//
//  ImportCoordinator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import Foundation
import PDFKit
import PhotosUI
import SwiftUI
import VisionKit

@MainActor
@Observable
final class ImportCoordinator {
    enum ImportSource {
        case scan
        case photo
        case pdf
        case paste
    }

    enum Stage: Equatable {
        case idle
        case reading(page: Int, of: Int)
        case drafting
    }

    struct DraftingStatus: Equatable {
        let title: String
        let detail: String
        let fraction: Double?
    }

    struct PageChoice {
        let fileName: String
        let document: PDFDocument
    }

    /// `title` names the document inside the draft; `displayTitle` is what Library
    /// shows while it drafts.
    private struct DraftRequest {
        let extracted: ExtractedDocument
        let title: String
        let displayTitle: String
        let sourceType: StudySourceType
    }

    /// Generation failures re-draft the text already read off the page; read failures
    /// have nothing to reuse and send the user back to capture.
    private enum RetrySource {
        case document(DraftRequest)
        case capture(ImportSource)
    }

    var draftStore: DraftStore?
    var aiSettings: AISettings?
    var storeController: StoreController?
    var failure: ImportFailure? = nil
    var showReview = false
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var showPasteSheet = false
    var showPagePicker = false
    var showHostedConsent = false
    var showTypeCards = false
    var pasteSeedText = ""
    var pendingSource: ImportSource? = nil
    var selectedPhotoItem: PhotosPickerItem? = nil
    var showPhotoPicker = false
    var showReplaceDraftAlert = false
    var showPaywall = false
    var hasUnlimitedGenerations = false
    private(set) var stage: Stage = .idle
    private(set) var pageChoice: PageChoice? = nil

    private var draftingTitle: String? = nil
    private var readingShare = 0.0
    private var retrySource: RetrySource? = nil
    private var retainedText = ""
    private var pendingOCRImages: [UIImage]? = nil
    private var pendingScannerFailure = false
    private var pendingPasteText: String? = nil
    private var chosenPageIndices: [Int]? = nil
    private var awaitingConsent: DraftRequest? = nil
    private var pendingConsentDecision: HostedConsent.Decision? = nil
    private var generationTask: Task<Void, Never>? = nil

    var isScannerSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return VNDocumentCameraViewController.isSupported
        #endif
    }

    /// Bring-your-own-key generation isn't metered by the free monthly allowance: it
    /// has no allowance to run out of, and sending those users to the Pro paywall would
    /// be selling them a subscription their own key already replaces.
    var canStartGeneration: Bool {
        if aiSettings?.mode == .externalAPI { return true }
        return hasUnlimitedGenerations || !GenerationAllowance.isExhausted
    }

    var replaceDraftMessage: String {
        if stage != .idle, let draftingTitle {
            return "QuickStudy is still drafting \(draftingTitle). Starting a new set will cancel it."
        }
        if let draft = draftStore?.pending {
            return "You have a draft from \(draft.title) waiting. Starting a new set will discard it."
        }
        return ""
    }

    // MARK: - Starting an import

    func openSourcePicker() {
        if isManualOnly {
            showTypeCards = true
        } else if !canStartGeneration {
            presentPaywall()
        } else if hasWorkToReplace {
            showReplaceDraftAlert = true
        } else {
            showSourcePicker = true
        }
    }

    /// Presenting a sheet while another is dismissing drops the second one, so the
    /// picker records a choice and this runs once it has fully dismissed.
    func presentPendingSource() {
        guard pendingSource != nil else { return }
        guard canStartGeneration else {
            pendingSource = nil
            retrySource = nil
            presentPaywall()
            return
        }
        // A second draft would overwrite the first, and the first cost a generation.
        guard !hasWorkToReplace else {
            showReplaceDraftAlert = true
            return
        }
        proceedWithPendingSource()
    }

    func replacePendingDraft() {
        cancelGeneration()
        draftStore?.set(nil)
        if pendingSource == nil {
            showSourcePicker = true
        } else {
            presentPendingSource()
        }
    }

    func cancelReplaceDraft() {
        pendingSource = nil
    }

    func presentPaywall() {
        showPaywall = true
    }

    func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
    }

    private var hasWorkToReplace: Bool {
        stage != .idle || draftStore?.pending != nil
    }

    /// No local model, and the free hosted generation is spent or the cloud was declined,
    /// so the only way to add cards is typing them.
    private var isManualOnly: Bool {
        guard let aiSettings, let storeController,
              AICapability.state(for: aiSettings) == .unsupportedDevice else { return false }
        return !storeController.isPro
            && (storeController.freeHostedGenerationUsed || HostedConsent.decision == .declined)
    }

    private func proceedWithPendingSource() {
        guard let source = pendingSource else { return }
        pendingSource = nil
        retrySource = nil
        retainedText = ""
#if canImport(FoundationModels)
        OnDeviceCardGenerationEngine.prewarm()
#endif
        if let aiSettings, AIController.mayUsePrivateCloud(settings: aiSettings) {
            PrivateCloud.prewarm()
        }
        switch source {
        case .scan:
            guard checkOnDeviceReadiness() else { return }
            startScan()
        case .photo:
            guard checkOnDeviceReadiness() else { return }
            showPhotoPicker = true
        case .pdf:
            guard checkOnDeviceReadiness() else { return }
            showFileImporter = true
        case .paste:
            showPasteSheet = true
        }
    }

    /// Apple Intelligence being off or still downloading is knowable before capture.
    /// Surfacing it after a scan or PDF import wastes the read and looks like OCR failed.
    /// A user who hasn't been asked about the cloud yet may still draft there.
    private func checkOnDeviceReadiness() -> Bool {
        guard let aiSettings, aiSettings.mode == .onDevice,
              let storeController, !storeController.willUseHostedGeneration,
              !needsConsent(sourceLength: 0) else { return true }
#if canImport(FoundationModels)
        do {
            try OnDeviceModelAvailability.check()
            return true
        } catch let error as CardGenerationError {
            switch error {
            case .appleIntelligenceNotEnabled, .modelNotReady:
                fail(.deviceNotReady(
                    message: error.errorDescription ?? "On-device AI isn't ready yet. Try again in a few minutes."
                ))
                return false
            default:
                return true
            }
        } catch {
            return true
        }
#else
        return true
#endif
    }

    // MARK: - Cloud consent

    /// The engines `AIController` would try for this draft if the user allowed the cloud,
    /// so the consent question is only asked when the answer changes where it runs.
    private func enginesIfAllowed(sourceLength: Int) -> [GenerationProvenance.Engine] {
        guard let aiSettings, let storeController else { return [] }
        let privateCloudReady = if case .ready = PrivateCloud.status { true } else { false }
        return AIController.plan(
            for: DraftingConditions(
                mode: aiSettings.mode,
                consent: HostedConsent.decision ?? .granted,
                isPro: storeController.isPro,
                freeHostedGenerationUnused: !storeController.freeHostedGenerationUsed,
                hasOnDeviceModel: AIController.isOnDeviceModelAvailable,
                privateCloudReady: privateCloudReady
            ),
            sourceLength: sourceLength
        )
    }

    private func needsConsent(sourceLength: Int) -> Bool {
        HostedConsent.decision == nil
            && enginesIfAllowed(sourceLength: sourceLength).contains { $0 == .privateCloud || $0 == .cloud }
    }

    /// Recorded on tap rather than on dismiss so the Library's entitlement refresh, which
    /// runs as the sheet closes, already sees the choice.
    func recordConsentChoice(_ decision: HostedConsent.Decision) {
        HostedConsent.record(decision)
        pendingConsentDecision = decision
    }

    /// Fires once the consent sheet has fully dismissed. A swipe-to-dismiss leaves no
    /// recorded choice, which cancels the import as if it never started.
    func resumeAfterConsent(study: StudyViewModel) {
        defer { pendingConsentDecision = nil }
        guard let request = awaitingConsent else { return }
        awaitingConsent = nil
        guard let decision = pendingConsentDecision else {
            discardRetainedWork()
            return
        }
        if decision == .declined {
            // Without an on-device model a decline leaves nothing that can draft, and the
            // consent copy promises Type cards instead.
            if let aiSettings, AICapability.state(for: aiSettings) == .unsupportedDevice {
                discardRetainedWork()
                showTypeCards = true
                return
            }
            guard checkOnDeviceReadiness() else { return }
        } else if let aiSettings, AIController.mayUsePrivateCloud(settings: aiSettings) {
            PrivateCloud.prewarm()
        }
        generationTask = Task { await self.startDrafting(request, study: study) }
    }

    // MARK: - Capture handoff

    /// The document scanner hands back images at completion; they're stashed here so
    /// OCR starts from the cover's `onDismiss`, after it has fully closed, and anything
    /// it presents next isn't dropped.
    func stashScannedImages(_ images: [UIImage]) {
        pendingOCRImages = images
    }

    func stashScannerFailure() {
        pendingScannerFailure = true
    }

    func startPendingOCR(using helper: DocumentImportHelper, study: StudyViewModel) {
        if pendingScannerFailure {
            pendingScannerFailure = false
            retrySource = .capture(.scan)
            fail(.processing(message: "The camera stopped before the scan finished. Please try again."))
            return
        }
        guard let images = pendingOCRImages else { return }
        pendingOCRImages = nil
        generationTask = Task { await self.processOCR(images: images, using: helper, study: study) }
    }

    func stashPastedText(_ text: String) {
        pendingPasteText = text
    }

    /// Fires from the paste sheet's `onDismiss`. See `stashScannedImages` for why.
    func finishPasteSheetDismiss(study: StudyViewModel) {
        pasteSeedText = ""
        guard let text = pendingPasteText else { return }
        pendingPasteText = nil
        generationTask = Task { await self.processPastedText(text, study: study) }
    }

    func startPhotoProcessing(using helper: DocumentImportHelper, study: StudyViewModel) {
        // Clearing the selection fires this again; that pass must not replace the task.
        guard selectedPhotoItem != nil else { return }
        generationTask = Task { await self.handleSelectedPhoto(using: helper, study: study) }
    }

    func handleFileImport(_ result: Result<URL, Error>, using helper: DocumentImportHelper, study: StudyViewModel) {
        switch result {
        case .success(let url):
            generationTask = Task { await self.openPDF(url: url, using: helper, study: study) }
        case .failure:
            retrySource = .capture(.pdf)
            fail(.processing(message: "Failed to open the file. Try a different document."))
        }
    }

    func choosePages(_ indices: [Int]) {
        chosenPageIndices = indices
    }

    /// Fires from the page picker's `onDismiss`. Closing it without choosing cancels.
    func finishPageChoice(using helper: DocumentImportHelper, study: StudyViewModel) {
        guard let choice = pageChoice else { return }
        pageChoice = nil
        let indices = chosenPageIndices
        chosenPageIndices = nil
        guard let indices, !indices.isEmpty else { return }
        generationTask = Task {
            await self.readPDF(choice.document, fileName: choice.fileName, pageIndices: indices, using: helper, study: study)
        }
    }

    /// Cooperative cancellation: as long as the engine call honors it, `draftOrFail`
    /// never reaches the point that records a draft or charges the allowance.
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        stage = .idle
        draftingTitle = nil
    }

    // MARK: - Failure and recovery

    func dismissFailure() {
        failure = nil
        discardRetainedWork()
    }

    func recover(_ recovery: ImportFailure.Recovery, using helper: DocumentImportHelper, study: StudyViewModel) {
        failure = nil
        switch recovery {
        case .pasteText:
            pasteSeedText = retainedText
            showPasteSheet = true
        case .tryAgain:
            retry(study: study)
        case .typeCards:
            showTypeCards = true
        }
    }

    private func retry(study: StudyViewModel) {
        guard let retrySource else { return }
        switch retrySource {
        case let .document(request):
            generationTask = Task { await self.startDrafting(request, study: study) }
        case let .capture(source):
            pendingSource = source
            presentPendingSource()
        }
    }

    private func fail(_ failure: ImportFailure) {
        stage = .idle
        draftingTitle = nil
        self.failure = failure
    }

    /// A user Cancel must look identical to never having started: no failure shown.
    private func failIfNotCancelled(_ failure: ImportFailure) {
        guard !Task.isCancelled else { return }
        fail(failure)
    }

    private func discardRetainedWork() {
        retrySource = nil
        retainedText = ""
    }

    // MARK: - Drafting status

    func draftingStatus(progress: GenerationProgress, now: Date = .now) -> DraftingStatus? {
        guard let draftingTitle else { return nil }
        let title = "Drafting \(draftingTitle)"
        switch stage {
        case .idle:
            return nil
        case let .reading(page, total):
            let pages = max(total, 1)
            return DraftingStatus(
                title: title,
                detail: "Reading page \(min(page + 1, pages)) of \(pages)",
                fraction: readingShare * Double(min(page, pages)) / Double(pages)
            )
        case .drafting:
            guard progress.startedAt != nil else {
                return DraftingStatus(title: title, detail: "Drafting cards", fraction: readingShare > 0 ? readingShare : nil)
            }
            let fraction = readingShare + (1 - readingShare) * progress.fraction(now: now)
            if progress.isChunked {
                let current = min(progress.completedUnits + 1, progress.totalUnits)
                return DraftingStatus(title: title, detail: "Drafting cards · \(current) of \(progress.totalUnits)", fraction: fraction)
            }
            guard let timeLeft = Self.timeLeft(in: progress, now: now) else {
                return DraftingStatus(title: title, detail: "Drafting cards", fraction: fraction)
            }
            return DraftingStatus(title: title, detail: "Drafting cards · \(timeLeft)", fraction: fraction)
        }
    }

    private static func timeLeft(in progress: GenerationProgress, now: Date) -> String? {
        guard let unitStartedAt = progress.unitStartedAt else { return nil }
        let remaining = progress.expectedSeconds - now.timeIntervalSince(unitStartedAt)
        guard remaining > 0 else { return nil }
        guard remaining >= 60 else {
            return "about \(max(5, Int((remaining / 5).rounded()) * 5)) seconds left"
        }
        let minutes = Int((remaining / 60).rounded(.up))
        return "about \(minutes) \(minutes == 1 ? "minute" : "minutes") left"
    }

    /// Reading pages is fast next to drafting, so it gets a small slice of the bar and
    /// drafting continues from there instead of restarting at zero.
    private func beginRun(title: String, stage: Stage, readingShare: Double) {
        failure = nil
        draftingTitle = title
        self.readingShare = readingShare
        self.stage = stage
    }

    /// A cancelled run has already been reset by `cancelGeneration`, and a new run may
    /// have started since, so only a run that finished on its own clears the status.
    private func endRun() {
        guard !Task.isCancelled else { return }
        stage = .idle
        draftingTitle = nil
    }

    /// A Cancel followed by a new import must not let the old run's page count overwrite
    /// the new one, and nothing may pull the status back from drafting.
    private func advanceReading(page: Int, of total: Int) {
        guard !Task.isCancelled, case .reading = stage else { return }
        stage = .reading(page: page, of: total)
    }

    // MARK: - Drafting

    /// Every source funnels through here so consent, the retained text, the retry target
    /// and the failure shape are identical no matter how the page was read.
    private func startDrafting(_ request: DraftRequest, study: StudyViewModel) async {
        guard !Task.isCancelled else { return }
        guard canStartGeneration else {
            discardRetainedWork()
            fail(.quotaExhausted(resetDate: GenerationAllowance.resetDate()))
            return
        }
        retrySource = .document(request)
        retainedText = request.extracted.joinedText

        if needsConsent(sourceLength: retainedText.utf16.count) {
            awaitingConsent = request
            stage = .idle
            draftingTitle = nil
            showHostedConsent = true
            return
        }

        if case .reading = stage {
            stage = .drafting
        } else {
            beginRun(title: request.displayTitle, stage: .drafting, readingShare: 0)
        }
        defer { endRun() }

        guard let draft = await study.makeDraft(
            from: request.extracted,
            title: request.title,
            sourceType: request.sourceType
        ) else {
            failIfNotCancelled(.generation(cause: study.generationErrorMessage))
            return
        }
        guard !Task.isCancelled else { return }
        draftStore?.set(draft)
        discardRetainedWork()
    }

    private func processPastedText(_ text: String, study: StudyViewModel) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fail(.emptyPaste)
            return
        }
        await startDrafting(
            DraftRequest(
                extracted: ExtractedDocument(pages: [.init(text: trimmed, candidates: [])]),
                title: "Pasted Notes",
                displayTitle: SetTitleSuggester.title(from: trimmed.components(separatedBy: .newlines).flatMap(StudyViewModel.sentenceLines)) ?? "Pasted Notes",
                sourceType: .paste
            ),
            study: study
        )
    }

    private func processOCR(images: [UIImage], using helper: DocumentImportHelper, study: StudyViewModel) async {
        beginRun(title: "Scan", stage: .reading(page: 0, of: images.count), readingShare: 0.15)
        defer { endRun() }

        do {
            let extracted = try await helper.extractText(from: images) { page, total in
                advanceReading(page: page, of: total)
            }
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                retrySource = .capture(.scan)
                fail(.noText(message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."))
                return
            }
            await startDrafting(
                DraftRequest(extracted: extracted, title: "Scanned Document", displayTitle: "Scan", sourceType: .scan),
                study: study
            )
        } catch {
            retrySource = .capture(.scan)
            failIfNotCancelled(.processing(message: "Failed to process the scan. Please try again."))
        }
    }

    private func openPDF(url: URL, using helper: DocumentImportHelper, study: StudyViewModel) async {
        let fileName = url.deletingPathExtension().lastPathComponent
        do {
            let document = try await helper.openPDF(at: url)
            guard !Task.isCancelled else { return }
            guard document.pageCount <= ChoosePagesViewModel.pageLimit else {
                pageChoice = PageChoice(fileName: fileName, document: document)
                showPagePicker = true
                return
            }
            await readPDF(document, fileName: fileName, pageIndices: nil, using: helper, study: study)
        } catch DocumentImportError.unreadablePDF {
            retrySource = .capture(.pdf)
            failIfNotCancelled(.unreadablePDF())
        } catch {
            retrySource = .capture(.pdf)
            failIfNotCancelled(.processing(message: "Failed to import the PDF. Please check the file and try again."))
        }
    }

    private func readPDF(
        _ document: PDFDocument,
        fileName: String,
        pageIndices: [Int]?,
        using helper: DocumentImportHelper,
        study: StudyViewModel
    ) async {
        beginRun(
            title: fileName,
            stage: .reading(page: 0, of: pageIndices?.count ?? document.pageCount),
            readingShare: 0.15
        )
        defer { endRun() }

        do {
            let extracted = try await helper.extractText(from: document, pageIndices: pageIndices) { page, total in
                advanceReading(page: page, of: total)
            }
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                retrySource = .capture(.pdf)
                fail(.noText(message: "No text was detected. This PDF may be a scan of a page rather than text."))
                return
            }
            await startDrafting(
                DraftRequest(extracted: extracted, title: fileName, displayTitle: fileName, sourceType: .pdf),
                study: study
            )
        } catch {
            retrySource = .capture(.pdf)
            failIfNotCancelled(.processing(message: "Failed to import the PDF. Please check the file and try again."))
        }
    }

    private func handleSelectedPhoto(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let item = selectedPhotoItem else { return }
        selectedPhotoItem = nil
        retrySource = .capture(.photo)
        beginRun(title: "Photo", stage: .reading(page: 0, of: 1), readingShare: 0.15)
        defer { endRun() }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                failIfNotCancelled(.processing(message: "Could not load the selected photo. Try a different image."))
                return
            }
            guard !Task.isCancelled else { return }
            let extracted = try await helper.extractText(from: [image]) { page, total in
                advanceReading(page: page, of: total)
            }
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                fail(.noText(message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."))
                return
            }
            await startDrafting(
                DraftRequest(extracted: extracted, title: "Photo", displayTitle: "Photo", sourceType: .photo),
                study: study
            )
        } catch {
            failIfNotCancelled(.processing(message: "Failed to process the photo. Please try again."))
        }
    }
}

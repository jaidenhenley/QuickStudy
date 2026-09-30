//
//  ImportCoordinator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import Foundation
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

    /// What `Try again` re-runs. Generation failures re-draft the text already read off
    /// the page; read failures have nothing to reuse and send the user back to capture.
    enum RetrySource {
        case document(ExtractedDocument, title: String, sourceType: StudySourceType)
        case capture(ImportSource)
    }

    enum PostErrorAction {
        case none
        case paste
        case retry
        case typeCards
    }

    var navigateToReview = false
    var previewConfirmed = false
    var draftStore: DraftStore?
    var aiSettings: AISettings?
    var storeController: StoreController?
    var failure: ImportFailure? = nil
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var showPasteSheet = false
    var showHostedConsent = false
    var showTypeCards = false
    var pasteSeedText = ""
    var pendingSource: ImportSource? = nil
    var selectedPhotoItem: PhotosPickerItem? = nil
    var showPhotoPicker = false
    var showGenerating = false
    var showReplaceDraftAlert = false
    var showPaywall = false
    var hasUnlimitedGenerations = false
    var stage: Stage = .idle
    /// Drives the Generating screen's source-appropriate wording.
    var activeSource: ImportSource? = nil

    private var pendingFailure: ImportFailure? = nil
    private var postErrorAction: PostErrorAction = .none
    private var retrySource: RetrySource? = nil
    private var retainedText = ""
    private var pendingOCRImages: [UIImage]? = nil
    private var pendingScannerFailure = false
    private var pendingPasteText: String? = nil
    private var pendingConsentDecision: HostedConsent.Decision? = nil
    /// Owned so Cancel on the Generating screen can actually stop the in-flight work
    /// instead of merely hiding the cover.
    private var generationTask: Task<Void, Never>? = nil

    var isScannerSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return VNDocumentCameraViewController.isSupported
        #endif
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
        guard draftStore?.pending == nil else {
            showReplaceDraftAlert = true
            return
        }
        if let aiSettings, let storeController,
           AIController.requiresHostedConsent(settings: aiSettings, store: storeController) {
            showHostedConsent = true
            return
        }
        proceedWithPendingSource()
    }

    func recordConsentChoice(_ decision: HostedConsent.Decision) {
        pendingConsentDecision = decision
    }

    /// Fires once the consent sheet has fully dismissed. A swipe-to-dismiss leaves no
    /// recorded choice, which this treats as cancelling the whole generation.
    func resumeAfterConsent() {
        defer { pendingConsentDecision = nil }
        guard let decision = pendingConsentDecision else {
            pendingSource = nil
            retrySource = nil
            return
        }
        HostedConsent.record(decision)
        proceedWithPendingSource()
    }

    private func proceedWithPendingSource() {
        guard let source = pendingSource else { return }
        pendingSource = nil
        retrySource = nil
        retainedText = ""
#if canImport(FoundationModels)
        OnDeviceCardGenerationEngine.prewarm()
#endif
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

    /// Bring-your-own-key generation isn't metered by the free monthly allowance — it
    /// has no allowance to run out of, and sending those users to the Pro paywall would
    /// be selling them a subscription their own key already replaces.
    var canStartGeneration: Bool {
        if aiSettings?.mode == .externalAPI { return true }
        return hasUnlimitedGenerations || !GenerationAllowance.isExhausted
    }

    func presentPaywall() {
        showPaywall = true
    }

    private func presentQuotaExhausted() {
        fail(.quotaExhausted(resetDate: GenerationAllowance.resetDate()))
    }

    /// Apple Intelligence being off or still downloading is knowable before capture —
    /// surfacing it after a scan or PDF import wastes the read and looks like OCR failed.
    private func checkOnDeviceReadiness() -> Bool {
        guard let aiSettings, aiSettings.mode == .onDevice,
              let storeController, !storeController.willUseHostedGeneration else { return true }
#if canImport(FoundationModels)
        do {
            try OnDeviceModelAvailability.check()
            return true
        } catch let error as CardGenerationError {
            switch error {
            case .appleIntelligenceNotEnabled, .modelNotReady:
                fail(.deviceNotReady(
                    message: error.errorDescription ?? "On-device AI isn't ready yet. Try again in a few minutes.",
                    code: error.code
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

    func replacePendingDraft() {
        draftStore?.set(nil)
        presentPendingSource()
    }

    func cancelReplaceDraft() {
        pendingSource = nil
    }

    func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
    }

    // MARK: - Generating screen sequencing

    /// The document scanner hands back images at completion; they're stashed here so the
    /// actual OCR + drafting Task starts from the sheet's `onDismiss`, after it has fully
    /// closed, rather than racing its dismissal animation.
    func stashScannedImages(_ images: [UIImage]) {
        pendingOCRImages = images
    }

    func stashScannerFailure() {
        pendingScannerFailure = true
    }

    func startPendingOCR(using helper: DocumentImportHelper, study: StudyViewModel) {
        if pendingScannerFailure {
            pendingScannerFailure = false
            fail(.processing(message: "The camera stopped before the scan finished. Please try again.", code: "QS-113"))
            return
        }
        guard let images = pendingOCRImages else { return }
        pendingOCRImages = nil
        generationTask = Task { await self.processOCR(images: images, using: helper, study: study) }
    }

    func stashPastedText(_ text: String) {
        pendingPasteText = text
    }

    /// Fires from the paste sheet's `onDismiss` — see `stashScannedImages` for why.
    func finishPasteSheetDismiss(study: StudyViewModel) {
        pasteSeedText = ""
        guard let text = pendingPasteText else { return }
        pendingPasteText = nil
        generationTask = Task { await self.processPastedText(text, study: study) }
    }

    func startPDFImport(url: URL, using helper: DocumentImportHelper, study: StudyViewModel) {
        generationTask = Task { await self.processPDF(url: url, using: helper, study: study) }
    }

    func startPhotoProcessing(using helper: DocumentImportHelper, study: StudyViewModel) {
        generationTask = Task { await self.handleSelectedPhoto(using: helper, study: study) }
    }

    /// Cooperative cancellation: this stops the Task, and as long as the engine call it's
    /// awaiting honors cancellation, `draftOrFail` never reaches the point that would
    /// record a draft, navigate to review, or charge the allowance.
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        showGenerating = false
    }

    // MARK: - Failure presentation

    /// The generating cover has to be fully down before the error screen goes up —
    /// same dropped-presentation problem as the source picker.
    private func fail(_ failure: ImportFailure) {
        if showGenerating {
            pendingFailure = failure
            showGenerating = false
        } else {
            self.failure = failure
        }
    }

    /// A user Cancel must look identical to never having started — no error screen, no
    /// navigation. This is the difference between that and a real failure.
    private func failIfNotCancelled(_ failure: ImportFailure) {
        guard !Task.isCancelled else { return }
        fail(failure)
    }

    func presentPendingFailure() {
        guard let pending = pendingFailure else { return }
        pendingFailure = nil
        failure = pending
    }

    func dismissFailure() {
        postErrorAction = .none
        failure = nil
    }

    func requestPasteRecovery() {
        postErrorAction = .paste
        failure = nil
    }

    func requestRetry() {
        postErrorAction = .retry
        failure = nil
    }

    func requestTypeCards() {
        postErrorAction = .typeCards
        failure = nil
    }

    func resumeAfterError(using helper: DocumentImportHelper, study: StudyViewModel) {
        let action = postErrorAction
        postErrorAction = .none
        switch action {
        case .none:
            break
        case .paste:
            pasteSeedText = retainedText
            showPasteSheet = true
        case .retry:
            generationTask = Task { await self.retry(using: helper, study: study) }
        case .typeCards:
            showTypeCards = true
        }
    }

    private func retry(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let retrySource else { return }
        switch retrySource {
        case let .document(extracted, title, sourceType):
            activeSource = Self.importSource(for: sourceType)
            stage = .drafting
            showGenerating = true
            defer { stage = .idle; showGenerating = false; activeSource = nil }
            await draftOrFail(from: extracted, title: title, sourceType: sourceType, study: study)
        case let .capture(source):
            pendingSource = source
            presentPendingSource()
        }
    }

    private static func importSource(for sourceType: StudySourceType) -> ImportSource? {
        switch sourceType {
        case .scan: return .scan
        case .photo: return .photo
        case .pdf: return .pdf
        case .paste: return .paste
        case .demo, .manual: return nil
        }
    }

    // MARK: - Drafting

    /// Every source funnels through here so the retained text, the retry target and the
    /// failure shape are identical no matter how the page was read.
    private func draftOrFail(
        from extracted: ExtractedDocument,
        title: String,
        sourceType: StudySourceType,
        study: StudyViewModel
    ) async {
        guard canStartGeneration else {
            retrySource = nil
            presentQuotaExhausted()
            return
        }
        retrySource = .document(extracted, title: title, sourceType: sourceType)
        retainedText = extracted.joinedText

        guard let draft = await study.makeDraft(from: extracted, title: title, sourceType: sourceType) else {
            failIfNotCancelled(.generation(
                cause: study.generationErrorMessage,
                code: study.generationErrorCode,
                retained: sourceType == .scan || sourceType == .photo ? "the text from your scan" : "your text"
            ))
            return
        }
        guard !Task.isCancelled else { return }
        draftStore?.set(draft)
        previewConfirmed = false
        navigateToReview = true
    }

    func processPastedText(_ text: String, study: StudyViewModel) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            fail(.emptyPaste)
            return
        }
        activeSource = .paste
        stage = .drafting
        showGenerating = true
        defer { stage = .idle; showGenerating = false; activeSource = nil }

        await draftOrFail(
            from: ExtractedDocument(pages: [.init(text: trimmed, candidates: [])]),
            title: "Pasted Notes",
            sourceType: .paste,
            study: study
        )
    }

    func processOCR(images: [UIImage], using helper: DocumentImportHelper, study: StudyViewModel) async {
        activeSource = .scan
        stage = .reading(page: 0, of: images.count)
        showGenerating = true
        defer { stage = .idle; showGenerating = false; activeSource = nil }

        do {
            let extracted = try await helper.extractText(from: images) { page, total in
                Task { @MainActor in self.stage = .reading(page: page, of: total) }
            }
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                retrySource = .capture(.scan)
                failIfNotCancelled(.noText(
                    navigationTitle: "Scan failed",
                    message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."
                ))
                return
            }
            stage = .drafting
            await draftOrFail(from: extracted, title: "Scanned Document", sourceType: .scan, study: study)
        } catch {
            retrySource = .capture(.scan)
            failIfNotCancelled(.processing(message: "Failed to process the scan. Please try again.", code: "QS-110"))
        }
    }

    func processPDF(url: URL, using helper: DocumentImportHelper, study: StudyViewModel) async {
        activeSource = .pdf
        stage = .reading(page: 0, of: 1)
        showGenerating = true
        defer { stage = .idle; showGenerating = false; activeSource = nil }

        do {
            let extracted = try await helper.extractText(from: url) { page, total in
                Task { @MainActor in self.stage = .reading(page: page, of: total) }
            }
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                retrySource = .capture(.pdf)
                failIfNotCancelled(.noText(
                    navigationTitle: "Import failed",
                    message: "No text was detected. This PDF may be a scan of a page rather than text."
                ))
                return
            }
            stage = .drafting
            await draftOrFail(
                from: extracted,
                title: url.deletingPathExtension().lastPathComponent,
                sourceType: .pdf,
                study: study
            )
        } catch {
            retrySource = .capture(.pdf)
            failIfNotCancelled(.processing(message: "Failed to import the PDF. Please check the file and try again.", code: "QS-120"))
        }
    }

    func handleSelectedPhoto(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let item = selectedPhotoItem else { return }
        selectedPhotoItem = nil
        activeSource = .photo
        retrySource = .capture(.photo)
        defer { activeSource = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                failIfNotCancelled(.processing(message: "Could not load the selected photo. Try a different image.", code: "QS-111"))
                return
            }
            guard !Task.isCancelled else { return }
            stage = .reading(page: 0, of: 1)
            showGenerating = true
            defer { stage = .idle; showGenerating = false }

            let extracted = try await helper.extractText(from: [image])
            guard !Task.isCancelled else { return }
            guard !extracted.isEmpty else {
                failIfNotCancelled(.noText(
                    navigationTitle: "Import failed",
                    message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."
                ))
                return
            }
            stage = .drafting
            await draftOrFail(from: extracted, title: "Photo", sourceType: .photo, study: study)
        } catch {
            failIfNotCancelled(.processing(message: "Failed to process the photo. Please try again.", code: "QS-112"))
        }
    }

    func handleFileImport(_ result: Result<URL, Error>, using helper: DocumentImportHelper, study: StudyViewModel) {
        switch result {
        case .success(let url):
            startPDFImport(url: url, using: helper, study: study)
        case .failure:
            retrySource = .capture(.pdf)
            fail(.processing(message: "Failed to open the file. Try a different document.", code: "QS-121"))
        }
    }
}

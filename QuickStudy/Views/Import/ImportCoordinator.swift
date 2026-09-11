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
    }

    var navigateToReview = false
    var previewConfirmed = false
    var draftStore: DraftStore?
    var failure: ImportFailure? = nil
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var showPasteSheet = false
    var pasteSeedText = ""
    var pendingSource: ImportSource? = nil
    var selectedPhotoItem: PhotosPickerItem? = nil
    var showPhotoPicker = false
    var showGenerating = false
    var stage: Stage = .idle

    private var pendingFailure: ImportFailure? = nil
    private var postErrorAction: PostErrorAction = .none
    private var retrySource: RetrySource? = nil
    private var retainedText = ""

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
        guard let source = pendingSource else { return }
        pendingSource = nil
        retrySource = nil
        retainedText = ""
#if canImport(FoundationModels)
        OnDeviceCardGenerationEngine.prewarm()
#endif
        switch source {
        case .scan:
            startScan()
        case .photo:
            showPhotoPicker = true
        case .pdf:
            showFileImporter = true
        case .paste:
            showPasteSheet = true
        }
    }

    func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
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
            Task { await retry(using: helper, study: study) }
        }
    }

    private func retry(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let retrySource else { return }
        switch retrySource {
        case let .document(extracted, title, sourceType):
            stage = .drafting
            showGenerating = true
            defer { stage = .idle; showGenerating = false }
            await draftOrFail(from: extracted, title: title, sourceType: sourceType, study: study)
        case let .capture(source):
            pendingSource = source
            presentPendingSource()
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
        retrySource = .document(extracted, title: title, sourceType: sourceType)
        retainedText = extracted.joinedText

        guard let draft = await study.makeDraft(from: extracted, title: title, sourceType: sourceType) else {
            fail(.generation(
                cause: study.generationErrorMessage,
                code: study.generationErrorCode,
                retainedNoun: sourceType == .scan || sourceType == .photo ? "scan" : "text"
            ))
            return
        }
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
        stage = .drafting
        showGenerating = true
        defer { stage = .idle; showGenerating = false }

        await draftOrFail(
            from: ExtractedDocument(pages: [.init(text: trimmed, candidates: [])]),
            title: "Pasted Notes",
            sourceType: .paste,
            study: study
        )
    }

    func processOCR(images: [UIImage], using helper: DocumentImportHelper, study: StudyViewModel) async {
        stage = .reading(page: 0, of: images.count)
        showGenerating = true
        defer { stage = .idle; showGenerating = false }

        do {
            let extracted = try await helper.extractText(from: images) { page, total in
                Task { @MainActor in self.stage = .reading(page: page, of: total) }
            }
            guard !extracted.isEmpty else {
                retrySource = .capture(.scan)
                fail(.noText(
                    navigationTitle: "Scan failed",
                    message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."
                ))
                return
            }
            stage = .drafting
            await draftOrFail(from: extracted, title: "Scanned Document", sourceType: .scan, study: study)
        } catch {
            retrySource = .capture(.scan)
            fail(.processing(message: "Failed to process the scan. Please try again.", code: "QS-110"))
        }
    }

    func processPDF(url: URL, using helper: DocumentImportHelper, study: StudyViewModel) async {
        stage = .reading(page: 0, of: 1)
        showGenerating = true
        defer { stage = .idle; showGenerating = false }

        do {
            let extracted = try await helper.extractText(from: url) { page, total in
                Task { @MainActor in self.stage = .reading(page: page, of: total) }
            }
            guard !extracted.isEmpty else {
                retrySource = .capture(.pdf)
                fail(.noText(
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
            fail(.processing(message: "Failed to import the PDF. Please check the file and try again.", code: "QS-120"))
        }
    }

    func handleSelectedPhoto(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let item = selectedPhotoItem else { return }
        selectedPhotoItem = nil
        retrySource = .capture(.photo)
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                fail(.processing(message: "Could not load the selected photo. Try a different image.", code: "QS-111"))
                return
            }
            stage = .reading(page: 0, of: 1)
            showGenerating = true
            defer { stage = .idle; showGenerating = false }

            let extracted = try await helper.extractText(from: [image])
            guard !extracted.isEmpty else {
                fail(.noText(
                    navigationTitle: "Import failed",
                    message: "No text was detected. Try better lighting, hold steady, or fill the frame with the page."
                ))
                return
            }
            stage = .drafting
            await draftOrFail(from: extracted, title: "Photo", sourceType: .photo, study: study)
        } catch {
            fail(.processing(message: "Failed to process the photo. Please try again.", code: "QS-112"))
        }
    }

    func handleFileImport(_ result: Result<URL, Error>, using helper: DocumentImportHelper, study: StudyViewModel) {
        switch result {
        case .success(let url):
            Task { await processPDF(url: url, using: helper, study: study) }
        case .failure:
            retrySource = .capture(.pdf)
            fail(.processing(message: "Failed to open the file. Try a different document.", code: "QS-121"))
        }
    }
}

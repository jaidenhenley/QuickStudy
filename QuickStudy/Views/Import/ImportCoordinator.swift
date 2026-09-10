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

    var navigateToReview = false
    var previewConfirmed = false
    var draftStore: DraftStore?
    var showErrorAlert = false
    var errorMessage = ""
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var showPasteSheet = false
    var pendingSource: ImportSource? = nil
    var selectedPhotoItem: PhotosPickerItem? = nil
    var showPhotoPicker = false
    var showGenerating = false
    var stage: Stage = .idle

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

    func processPastedText(_ text: String, study: StudyViewModel) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Paste some notes to generate cards from."
            showErrorAlert = true
            return
        }
        stage = .drafting
        showGenerating = true
        defer { stage = .idle; showGenerating = false }

        guard let draft = await study.makePastedDraft(trimmed) else {
            errorMessage = study.generationErrorMessage
                ?? "Couldn't draft any cards from those notes. Try a longer passage."
            showErrorAlert = true
            return
        }
        draftStore?.set(draft)
        previewConfirmed = false
        navigateToReview = true
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
                errorMessage = "No text found in the scanned image. Try scanning a different page."
                showErrorAlert = true
                return
            }
            stage = .drafting
            guard let draft = await study.makeDraft(from: extracted, title: "Scanned Document", sourceType: .scan) else {
                errorMessage = study.generationErrorMessage
                    ?? "Couldn't draft any cards from this. Try a different source."
                showErrorAlert = true
                return
            }
            draftStore?.set(draft)
            previewConfirmed = false
            navigateToReview = true
        } catch {
            errorMessage = "Failed to process the scan. Please try again."
            showErrorAlert = true
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
                errorMessage = "No text found in the PDF. Try a different document."
                showErrorAlert = true
                return
            }
            stage = .drafting
            guard let draft = await study.makeDraft(from: extracted, title: url.deletingPathExtension().lastPathComponent, sourceType: .pdf) else {
                errorMessage = study.generationErrorMessage
                    ?? "Couldn't draft any cards from this. Try a different source."
                showErrorAlert = true
                return
            }
            draftStore?.set(draft)
            previewConfirmed = false
            navigateToReview = true
        } catch {
            errorMessage = "Failed to import the PDF. Please check the file and try again."
            showErrorAlert = true
        }
    }

    func handleSelectedPhoto(using helper: DocumentImportHelper, study: StudyViewModel) async {
        guard let item = selectedPhotoItem else { return }
        selectedPhotoItem = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "Could not load the selected photo. Try a different image."
                showErrorAlert = true
                return
            }
            stage = .reading(page: 0, of: 1)
            showGenerating = true
            defer { stage = .idle; showGenerating = false }

            let extracted = try await helper.extractText(from: [image])
            guard !extracted.isEmpty else {
                errorMessage = "No text found in the photo. Try a different image."
                showErrorAlert = true
                return
            }
            stage = .drafting
            guard let draft = await study.makeDraft(from: extracted, title: "Photo", sourceType: .photo) else {
                errorMessage = study.generationErrorMessage
                    ?? "Couldn't draft any cards from this. Try a different source."
                showErrorAlert = true
                return
            }
            draftStore?.set(draft)
            previewConfirmed = false
            navigateToReview = true
        } catch {
            errorMessage = "Failed to process the photo. Please try again."
            showErrorAlert = true
        }
    }

    func handleFileImport(_ result: Result<URL, Error>, using helper: DocumentImportHelper, study: StudyViewModel) {
        switch result {
        case .success(let url):
            Task { await processPDF(url: url, using: helper, study: study) }
        case .failure(let error):
            errorMessage = "Failed to open the file: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

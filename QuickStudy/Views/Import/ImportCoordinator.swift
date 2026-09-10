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
        case pdf
        case paste
    }

    var navigateToCards = false
    var showErrorAlert = false
    var errorMessage = ""
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var showPasteSheet = false
    var pendingSource: ImportSource? = nil
    var selectedPhotoItem: PhotosPickerItem? = nil

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
        switch source {
        case .scan:
            startScan()
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
        study.currentSourceType = .paste
        await study.loadScannedText(rawText: trimmed, title: "Pasted Notes")
        navigateToCards = true
    }

    func processOCR(images: [UIImage], using helper: DocumentImportHelper, study: StudyViewModel) async {
        do {
            let result = try await helper.extractText(from: images)
            guard !result.text.isEmpty else {
                errorMessage = "No text found in the scanned image. Try scanning a different page."
                showErrorAlert = true
                return
            }
            study.currentSourceType = .scan
            await study.loadScannedText(rawText: result.text, candidateLines: result.candidates)
            navigateToCards = true
        } catch {
            errorMessage = "Failed to process the scan. Please try again."
            showErrorAlert = true
        }
    }

    func processPDF(url: URL, using helper: DocumentImportHelper, study: StudyViewModel) async {
        do {
            let text = try await helper.extractText(from: url)
            guard !text.isEmpty else {
                errorMessage = "No text found in the PDF. Try a different document."
                showErrorAlert = true
                return
            }
            study.currentSourceType = .pdf
            await study.loadScannedText(rawText: text)
            navigateToCards = true
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
            let result = try await helper.extractText(from: [image])
            guard !result.text.isEmpty else {
                errorMessage = "No text found in the photo. Try a different image."
                showErrorAlert = true
                return
            }
            study.currentSourceType = .photo
            await study.loadScannedText(rawText: result.text, candidateLines: result.candidates)
            navigateToCards = true
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

//
//  DashboardCoordinator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import Foundation
import PhotosUI
import SwiftUI

@Observable
final class DashboardCoordinator {
    var navigateToCards = false
    var showErrorAlert = false
    var errorMessage = ""
    var showScanCapture = false
    var showScannerUnavailableAlert = false
    var showFileImporter = false
    var showSourcePicker = false
    var selectedPhotoItem: PhotosPickerItem? = nil

    var isScannerSupported: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return VNDocumentCameraViewController.isSupported
        #endif
    }

    func startScan() {
        if isScannerSupported {
            showScanCapture = true
        } else {
            showScannerUnavailableAlert = true
        }
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

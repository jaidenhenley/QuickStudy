//
//  ImportModifiers.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ImportModifiers: ViewModifier {
    @Bindable var coordinator: ImportCoordinator
    let studyViewModel: StudyViewModel
    let appState: AppState
    let importHelper: DocumentImportHelper

    func body(content: Content) -> some View {
        content
            .alert("Camera Unavailable", isPresented: $coordinator.showScannerUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Document scanning isn't available in the simulator. Try on a real device.")
            }
            .alert("Error", isPresented: $coordinator.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(coordinator.errorMessage)
            }
            .navigationDestination(isPresented: $coordinator.navigateToCards) {
                CardsView()
                    .environment(studyViewModel)
                    .environment(appState)
            }
            .sheet(
                isPresented: $coordinator.showSourcePicker,
                onDismiss: { coordinator.presentPendingSource() }
            ) {
                NewSetSheet(coordinator: coordinator)
            }
            .sheet(isPresented: $coordinator.showPasteSheet) {
                PasteTextSheet { text in
                    Task { await coordinator.processPastedText(text, study: studyViewModel) }
                }
            }
            .sheet(isPresented: $coordinator.showScanCapture) {
                DocumentScannerView(
                    onComplete: { images in
                        coordinator.showScanCapture = false
                        Task { await coordinator.processOCR(images: images, using: importHelper, study: studyViewModel) }
                    },
                    onCancel: { coordinator.showScanCapture = false }
                )
            }
            .fileImporter(isPresented: $coordinator.showFileImporter, allowedContentTypes: [.pdf]) { result in
                coordinator.handleFileImport(result, using: importHelper, study: studyViewModel)
            }
            .photosPicker(
                isPresented: $coordinator.showPhotoPicker,
                selection: $coordinator.selectedPhotoItem,
                matching: .images
            )
            .fullScreenCover(isPresented: $coordinator.showGenerating) {
                GeneratingView(stage: coordinator.stage) {
                    coordinator.showGenerating = false
                }
            }
            .onChange(of: coordinator.selectedPhotoItem) { _, _ in
                Task { await coordinator.handleSelectedPhoto(using: importHelper, study: studyViewModel) }
            }
    }
}

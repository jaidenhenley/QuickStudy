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
    let draftStore: DraftStore
    let importHelper: DocumentImportHelper

    func body(content: Content) -> some View {
        content
            .alert("Camera Unavailable", isPresented: $coordinator.showScannerUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Document scanning isn't available in the simulator. Try on a real device.")
            }
            .navigationDestination(isPresented: $coordinator.navigateToReview) {
                if let draft = draftStore.pending {
                    if draft.cards.contains(where: { $0.source?.lineRange != nil }) {
                        ScanPreviewView(
                            draft: draft,
                            onContinue: { coordinator.previewConfirmed = true },
                            onCancel: {
                                draftStore.set(nil)
                                coordinator.navigateToReview = false
                            }
                        )
                        .navigationDestination(isPresented: $coordinator.previewConfirmed) {
                            ReviewDraftsView(draft: draft)
                                .environment(studyViewModel)
                                .environment(draftStore)
                        }
                    } else {
                        ReviewDraftsView(draft: draft)
                            .environment(studyViewModel)
                            .environment(draftStore)
                    }
                }
            }
            .onAppear { coordinator.draftStore = draftStore }
            .sheet(
                isPresented: $coordinator.showSourcePicker,
                onDismiss: { coordinator.presentPendingSource() }
            ) {
                NewSetSheet(coordinator: coordinator)
            }
            .sheet(
                isPresented: $coordinator.showPasteSheet,
                onDismiss: { coordinator.pasteSeedText = "" }
            ) {
                PasteTextSheet(initialText: coordinator.pasteSeedText) { text in
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
            .fullScreenCover(
                isPresented: $coordinator.showGenerating,
                onDismiss: { coordinator.presentPendingFailure() }
            ) {
                GeneratingView(stage: coordinator.stage) {
                    coordinator.showGenerating = false
                }
            }
            .fullScreenCover(
                item: $coordinator.failure,
                onDismiss: { coordinator.resumeAfterError(using: importHelper, study: studyViewModel) }
            ) { failure in
                ImportErrorView(
                    failure: failure,
                    onDismiss: { coordinator.dismissFailure() },
                    onPasteText: { coordinator.requestPasteRecovery() },
                    onTryAgain: { coordinator.requestRetry() }
                )
            }
            .onChange(of: coordinator.selectedPhotoItem) { _, _ in
                Task { await coordinator.handleSelectedPhoto(using: importHelper, study: studyViewModel) }
            }
    }
}

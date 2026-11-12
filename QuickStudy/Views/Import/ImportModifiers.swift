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
                Text("Document scanning isn't available on this device. Import a photo or PDF instead.")
            }
            .alert("Replace your draft?", isPresented: $coordinator.showReplaceDraftAlert) {
                Button("Replace", role: .destructive) { coordinator.replacePendingDraft() }
                Button("Cancel", role: .cancel) { coordinator.cancelReplaceDraft() }
            } message: {
                Text(coordinator.replaceDraftMessage)
            }
            .sheet(isPresented: $coordinator.showReview) {
                if let draft = draftStore.pending {
                    ReviewDraftsView(draft: draft)
                        .environment(studyViewModel)
                        .environment(draftStore)
                        .environment(studyViewModel.store)
                        .environment(studyViewModel.aiSettings)
                        .environment(studyViewModel.analytics)
                        .presentationDetents([.large])
                } else {
                    // Save and Discard clear the draft while the sheet is still animating away.
                    BackgroundView()
                        .ignoresSafeArea()
                }
            }
            .onAppear {
                coordinator.draftStore = draftStore
                coordinator.aiSettings = studyViewModel.aiSettings
                coordinator.storeController = studyViewModel.store
            }
            .onChange(of: draftStore.pending?.id) { _, id in
                guard id == nil else { return }
                coordinator.showReview = false
                coordinator.showDraftingProgress = false
            }
            .sheet(
                isPresented: $coordinator.showDraftingProgress,
                onDismiss: { coordinator.finishDraftingProgressDismiss() }
            ) {
                DraftingProgressSheet(
                    coordinator: coordinator,
                    progress: studyViewModel.generationProgress,
                    draftStore: draftStore
                )
            }
            .sheet(isPresented: $coordinator.showPaywall) {
                PaywallView(surface: .exhausted)
            }
            .sheet(
                isPresented: $coordinator.showSourcePicker,
                onDismiss: { coordinator.presentPendingSource() }
            ) {
                NewSetSheet(coordinator: coordinator)
            }
            .sheet(
                isPresented: $coordinator.showHostedConsent,
                onDismiss: { coordinator.resumeAfterConsent(study: studyViewModel) }
            ) {
                HostedConsentSheet(
                    setup: DraftingSetup.current(settings: studyViewModel.aiSettings),
                    onAllow: { coordinator.recordConsentChoice(.granted) },
                    onNotNow: { coordinator.recordConsentChoice(.declined) }
                )
            }
            .sheet(
                isPresented: $coordinator.showPasteSheet,
                onDismiss: { coordinator.finishPasteSheetDismiss(study: studyViewModel) }
            ) {
                PasteTextSheet(initialText: coordinator.pasteSeedText) { text in
                    coordinator.stashPastedText(text)
                }
            }
            .sheet(isPresented: $coordinator.showTypeCards) {
                TypeCardsView()
                    .environment(studyViewModel)
            }
            .fullScreenCover(
                isPresented: $coordinator.showScanCapture,
                onDismiss: { coordinator.startPendingOCR(using: importHelper, study: studyViewModel) }
            ) {
                DocumentScannerView(
                    onComplete: { images in
                        coordinator.stashScannedImages(images)
                        coordinator.showScanCapture = false
                    },
                    onCancel: { coordinator.showScanCapture = false },
                    onError: {
                        coordinator.stashScannerFailure()
                        coordinator.showScanCapture = false
                    }
                )
            }
            .fileImporter(isPresented: $coordinator.showFileImporter, allowedContentTypes: [.pdf]) { result in
                coordinator.handleFileImport(result, using: importHelper, study: studyViewModel)
            }
            .sheet(
                isPresented: $coordinator.showPagePicker,
                onDismiss: { coordinator.finishPageChoice(using: importHelper, study: studyViewModel) }
            ) {
                if let choice = coordinator.pageChoice {
                    ChoosePagesSheet(fileName: choice.fileName, document: choice.document) { indices in
                        coordinator.choosePages(indices)
                    }
                }
            }
            .photosPicker(
                isPresented: $coordinator.showPhotoPicker,
                selection: $coordinator.selectedPhotoItem,
                matching: .images
            )
            .onChange(of: coordinator.selectedPhotoItem) { _, _ in
                coordinator.startPhotoProcessing(using: importHelper, study: studyViewModel)
            }
    }
}

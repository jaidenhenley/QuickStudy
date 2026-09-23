//
//  LibraryView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct LibraryView: View {
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(AppState.self) private var appState
    @Environment(DraftStore.self) private var draftStore
    @Environment(AISettings.self) private var aiSettings
    @Environment(StoreController.self) private var store

    @State private var coordinator = ImportCoordinator()
    @State private var libraryViewModel = LibraryViewModel()
    @State private var renamingSet: StudySet? = nil
    @State private var renameText = ""
    @State private var showRenameAlert = false
    @State private var deletingSet: StudySet? = nil
    @State private var showDeleteAlert = false
    @State private var showTypeCards = false
    @State private var showPaywall = false

    var body: some View {
        @Bindable var libraryViewModel = libraryViewModel

        ZStack(alignment: .bottomTrailing) {
            BackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LibrarySearchField(
                        text: $libraryViewModel.searchText,
                        isEnabled: !studyViewModel.savedSets.isEmpty
                    )

                    if let draft = draftStore.pending,
                       !coordinator.navigateToReview,
                       !coordinator.showGenerating {
                        PendingDraftRow(
                            draft: draft,
                            onResume: {
                                coordinator.previewConfirmed = false
                                coordinator.navigateToReview = true
                            },
                            onDiscard: { draftStore.set(nil) }
                        )
                    }

                    // The empty state's three source buttons all require generation, so
                    // devices that can't generate right now get the ADD CARDS section instead.
                    if studyViewModel.savedSets.isEmpty && !libraryViewModel.showsAddCardsSection {
                        LibraryEmptyView(coordinator: coordinator)
                            .padding(.top, 32)
                    } else {
                        if !studyViewModel.savedSets.isEmpty {
                            LibraryFilterChips(selection: $libraryViewModel.filter)

                            let visible = libraryViewModel.sets(from: studyViewModel.savedSets)
                            if visible.isEmpty {
                                Text("No sets match this filter.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 48)
                            } else {
                                GlassEffectContainer {
                                    LazyVGrid(
                                        columns: [
                                            GridItem(.flexible(), spacing: Spacing.md),
                                            GridItem(.flexible(), spacing: Spacing.md)
                                        ],
                                        spacing: Spacing.md
                                    ) {
                                        ForEach(visible) { set in
                                            NavigationLink {
                                                StudySetDetailView(set: set)
                                            } label: {
                                                SetTile(set: set)
                                            }
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Button {
                                                    renameText = set.title
                                                    renamingSet = set
                                                    showRenameAlert = true
                                                } label: {
                                                    Label("Rename", systemImage: "pencil")
                                                }
                                                Button(role: .destructive) {
                                                    deletingSet = set
                                                    showDeleteAlert = true
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if let reason = libraryViewModel.addCardsReason {
                            AddCardsSection(
                                reason: reason,
                                onTypeCards: { showTypeCards = true },
                                onUpgrade: { showPaywall = true }
                            )
                            .padding(.top, studyViewModel.savedSets.isEmpty ? 32 : Spacing.lg)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 96)
            }

            FloatingCreateButton {
                if libraryViewModel.isManualOnly {
                    showTypeCards = true
                } else if !coordinator.canStartGeneration {
                    coordinator.presentPaywall()
                } else {
                    coordinator.showSourcePicker = true
                }
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshEntitlement()
            consumePendingSource()
        }
        .onChange(of: appState.pendingImportSource) { _, _ in consumePendingSource() }
        .onChange(of: aiSettings.mode) { _, _ in refreshEntitlement() }
        .onChange(of: store.isPro) { _, _ in refreshEntitlement() }
        .onChange(of: store.freeHostedGenerationUsed) { _, _ in refreshEntitlement() }
        .sheet(isPresented: $showTypeCards) {
            TypeCardsView()
                .environment(studyViewModel)
        }
        .sheet(isPresented: $showPaywall) { PaywallView(surface: .exhausted) }
        .alert("Rename Set", isPresented: $showRenameAlert) {
            TextField("Title", text: $renameText)
            Button("Save") {
                if let renamingSet {
                    studyViewModel.renameSet(id: renamingSet.id, title: renameText)
                }
                renamingSet = nil
            }
            Button("Cancel", role: .cancel) { renamingSet = nil }
        }
        .alert("Delete Set", isPresented: $showDeleteAlert, presenting: deletingSet) { set in
            Button("Delete", role: .destructive) {
                studyViewModel.deleteSet(set)
                deletingSet = nil
            }
            Button("Cancel", role: .cancel) { deletingSet = nil }
        } message: { set in
            Text("Delete \"\(set.title)\"? This cannot be undone.")
        }
        .modifier(
            ImportModifiers(
                coordinator: coordinator,
                studyViewModel: studyViewModel,
                appState: appState,
                draftStore: draftStore,
                importHelper: DocumentImportHelper(
                    isHandwritingMode: studyViewModel.isHandwritingMode,
                    isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
                )
            )
        )
    }

    private func consumePendingSource() {
        guard let source = appState.pendingImportSource else { return }
        appState.pendingImportSource = nil
        coordinator.pendingSource = source
        coordinator.presentPendingSource()
    }

    private func refreshEntitlement() {
        coordinator.hasUnlimitedGenerations = store.isPro
        libraryViewModel.refreshCapability(settings: aiSettings, store: store)
    }
}

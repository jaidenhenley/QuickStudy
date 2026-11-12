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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var coordinator = ImportCoordinator()
    @State private var libraryViewModel = LibraryViewModel()
    @State private var renamingSet: StudySet? = nil
    @State private var renameText = ""
    @State private var showRenameAlert = false
    @State private var deletingSet: StudySet? = nil
    @State private var showDeleteAlert = false
    @Namespace private var tileTransition

    var body: some View {
        @Bindable var libraryViewModel = libraryViewModel
        let importHelper = DocumentImportHelper(
            isHandwritingMode: studyViewModel.isHandwritingMode,
            isUltraHandwritingMode: studyViewModel.isUltraHandwritingMode
        )

        ZStack(alignment: .bottomTrailing) {
            BackgroundView()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LibrarySearchField(
                        text: $libraryViewModel.searchText,
                        isEnabled: !studyViewModel.savedSets.isEmpty
                    )

                    // The time left is derived from the clock, so the card has to re-render
                    // while a draft runs; it pauses once nothing is drafting.
                    TimelineView(.animation(minimumInterval: 1, paused: coordinator.stage == .idle)) { context in
                        if let card = LibraryViewModel.statusCard(
                            drafting: coordinator.draftingStatus(progress: studyViewModel.generationProgress, now: context.date),
                            failure: coordinator.failure,
                            draft: draftStore.pending
                        ) {
                            DraftStatusCard(
                                content: card,
                                onOpenProgress: { coordinator.openDraftingProgress() },
                                onReview: { coordinator.showReview = true },
                                onDiscard: { draftStore.set(nil) },
                                onClose: {
                                    if case .drafting = card {
                                        coordinator.cancelGeneration()
                                    } else {
                                        coordinator.dismissFailure()
                                    }
                                },
                                onRecover: { recovery in
                                    coordinator.recover(recovery, using: importHelper, study: studyViewModel)
                                }
                            )
                            .appTransition(.move(edge: .top).combined(with: .opacity))
                        }
                    }

                    if studyViewModel.savedSets.isEmpty {
                        LibraryEmptyView()
                            .padding(.top, 32)
                    } else {
                        if !studyViewModel.savedSets.isEmpty {
                            LibraryFilterChips(selection: $libraryViewModel.filter)

                            let visible = libraryViewModel.sets(from: studyViewModel.savedSets)
                            let query = libraryViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            Group {
                                if visible.isEmpty {
                                    Text(query.isEmpty ? "No sets match this filter." : "No sets match \u{201C}\(query)\u{201D}.")
                                        .multilineTextAlignment(.center)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.top, 48)
                                        .appTransition(.opacity)
                                } else {
                                    GlassEffectContainer {
                                        LazyVGrid(
                                            columns: Array(
                                                repeating: GridItem(.flexible(), spacing: Spacing.md),
                                                count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
                                            ),
                                            spacing: Spacing.md
                                        ) {
                                            ForEach(visible) { set in
                                                NavigationLink {
                                                    StudySetDetailView(set: set)
                                                        .appZoomNavigationTransition(sourceID: set.id, in: tileTransition)
                                                } label: {
                                                    SetTile(set: set)
                                                }
                                                .buttonStyle(.plain)
                                                // Without this the lift uses the link's full rectangle,
                                                // which shows as a grey platter around the rounded glass.
                                                .contentShape(.contextMenuPreview, .rect(cornerRadius: AppRadius.lg))
                                                .matchedTransitionSource(id: set.id, in: tileTransition) {
                                                    $0.clipShape(.rect(cornerRadius: AppRadius.lg))
                                                }
                                                .contextMenu {
                                                    Button { beginRename(set) } label: {
                                                        Label("Rename", systemImage: "pencil")
                                                    }
                                                    Button(role: .destructive) { beginDelete(set) } label: {
                                                        Label("Delete", systemImage: "trash")
                                                    }
                                                }
                                                .accessibilityAction(named: "Rename") { beginRename(set) }
                                                .accessibilityAction(named: "Delete") { beginDelete(set) }
                                                .appTransition(.opacity.combined(with: .scale(scale: 0.95)))
                                            }
                                        }
                                        .appAnimation(Motion.standard, value: libraryViewModel.filter)
                                        .appAnimation(Motion.standard, value: libraryViewModel.searchText)
                                    }
                                }
                            }
                            .appAnimation(Motion.standard, value: visible.isEmpty)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, 96)
                .appReadableWidth(alignment: .leading)
            }

            FloatingCreateButton { coordinator.openSourcePicker() }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshEntitlement()
            consumePendingSource()
        }
        .onChange(of: libraryViewModel.filter) { _, _ in announceResultCount() }
        .onChange(of: appState.pendingImportSource) { _, _ in consumePendingSource() }
        .onChange(of: aiSettings.mode) { _, _ in refreshEntitlement() }
        .onChange(of: store.isPro) { _, _ in refreshEntitlement() }
        .onChange(of: store.freeHostedGenerationUsed) { _, _ in refreshEntitlement() }
        // Nothing navigates when a draft finishes, so VoiceOver would otherwise miss it.
        .onChange(of: draftStore.pending?.id) { _, id in
            guard id != nil, let draft = draftStore.pending else { return }
            AccessibilityNotification.Announcement(LibraryViewModel.readyTitle(for: draft)).post()
        }
        .onChange(of: coordinator.showHostedConsent) { _, isShowing in
            guard !isShowing else { return }
            refreshEntitlement()
        }
        .appAnimation(Motion.standard, value: LibraryViewModel.statusCard(
            drafting: coordinator.draftingStatus(progress: studyViewModel.generationProgress),
            failure: coordinator.failure,
            draft: draftStore.pending
        )?.kind)
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
                importHelper: importHelper
            )
        )
    }

    private func beginRename(_ set: StudySet) {
        renameText = set.title
        renamingSet = set
        showRenameAlert = true
    }

    private func beginDelete(_ set: StudySet) {
        deletingSet = set
        showDeleteAlert = true
    }

    private func announceResultCount() {
        let count = libraryViewModel.sets(from: studyViewModel.savedSets).count
        let message = count == 0 ? "No sets" : "\(count) \(count == 1 ? "set" : "sets")"
        AccessibilityNotification.Announcement(message).post()
    }

    private func consumePendingSource() {
        guard let source = appState.pendingImportSource else { return }
        appState.pendingImportSource = nil
        // The onboarding handoff can land before ImportModifiers' onAppear has injected
        // these, and without them the consent and replace-draft checks are silently skipped.
        coordinator.draftStore = draftStore
        coordinator.aiSettings = aiSettings
        coordinator.storeController = store
        coordinator.pendingSource = source
        coordinator.presentPendingSource()
    }

    private func refreshEntitlement() {
        coordinator.hasUnlimitedGenerations = store.isPro
    }
}

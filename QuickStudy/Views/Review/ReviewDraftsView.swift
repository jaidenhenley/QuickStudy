//
//  ReviewDraftsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct ReviewDraftsView: View {
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(DraftStore.self) private var draftStore
    @Environment(StoreController.self) private var storeController
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var draft: DraftSet
    @State private var lastGeneratedCards: [StudyCard]
    @State private var isRegenerating = false
    @State private var showRegenerateError = false
    @State private var showRegenerateConfirm = false
    @State private var showPaywall = false
    @State private var showSave = false
    @State private var sourceCard: StudyCard?
    @State private var lastRemoval: (card: StudyCard, index: Int)?
    @State private var isFinished = false
    @State private var didSave = false
    @State private var showDiscardAlert = false
    @AccessibilityFocusState private var isHeaderFocused: Bool
    @AccessibilityFocusState private var accessibilityFocusedCardID: UUID?

    init(draft: DraftSet) {
        _draft = State(initialValue: draft)
        _lastGeneratedCards = State(initialValue: draft.cards)
    }

    var body: some View {
        NavigationStack {
            List {
                VStack(spacing: Spacing.xs) {
                    Text(headerSummary)
                    Text("Tap a card to edit. Swipe left to delete.")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isHeaderFocused)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                if draft.wasTruncated && !storeController.isPro {
                    TruncationNoticeRow { showPaywall = true }
                        .onAppear { analytics.record(.truncationEvent) }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .appTransition(.opacity.combined(with: .move(edge: .top)))
                }

                if draft.cards.isEmpty {
                    VStack(spacing: Spacing.md) {
                        Text("No cards left")
                            .font(.headline)
                        Text("Undo the last removal, or discard this draft.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        if lastRemoval != nil {
                            Button(action: undoRemoval) {
                                Label("Undo", systemImage: "arrow.uturn.backward")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .appProminentButtonStyle(tint: Theme.primaryFill)
                            .accessibilityHint("Restores the removed card")
                        }
                        Button(role: .destructive) {
                            showDiscardAlert = true
                        } label: {
                            Text("Discard")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.dangerText)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Spacing.base)
                    .appGlassCard(cornerRadius: AppRadius.lg)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .accessibilityElement(children: .contain)
                }

                ForEach($draft.cards) { $card in
                    DraftCardRow(
                        card: $card,
                        accessibilityFocusedCardID: $accessibilityFocusedCardID,
                        onDelete: { removeCard(card.id) },
                        onShowSource: CardSourceSheet.canShow(card, in: draft.document)
                            ? { sourceCard = card }
                            : nil
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .appTransition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeCard(card.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Theme.danger)
                    }
                }

                if !draft.cards.isEmpty {
                    Group {
                        if isRegenerating {
                            ProgressView()
                                .accessibilityLabel("Regenerating")
                        } else {
                            Button {
                                if hasUnsavedEdits {
                                    showRegenerateConfirm = true
                                } else {
                                    Task { await regenerate() }
                                }
                            } label: {
                                Label("Regenerate", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Theme.primary)
                                    .frame(minHeight: 44)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(BackgroundView())
            .navigationTitle("Review Cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Cards", systemImage: "checkmark") { showSave = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primaryFill)
                        .disabled(validCards.isEmpty || isRegenerating)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if lastRemoval != nil && !draft.cards.isEmpty {
                    Button(action: undoRemoval) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .appProminentButtonStyle(tint: Theme.primaryFill)
                    .accessibilityHint("Restores the removed card")
                    .padding(.bottom, Spacing.sm)
                    .appTransition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .presentationDetents([.large])
        .task(id: lastRemoval?.card.id) {
            guard lastRemoval != nil, !voiceOverEnabled else { return }
            // Left up under VoiceOver: a 5 second window is too short to find and activate Undo.
            // Cancellation means a newer removal or an undo already replaced this one.
            do { try await Task.sleep(for: .seconds(5)) } catch { return }
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                lastRemoval = nil
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: draft.cards.count) { old, new in new < old }
        .sensoryFeedback(.success, trigger: didSave) { _, saved in saved }
        .alert("Discard Draft?", isPresented: $showDiscardAlert) {
            Button("Discard Draft", role: .destructive, action: discard)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(draft.discardWarning)
        }
        .onChange(of: draft.cards) { _, _ in persistDraft() }
        .confirmationDialog(
            "Replace \(draft.cards.count) cards?",
            isPresented: $showRegenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) { Task { await regenerate() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your edits will be lost.")
        }
        .alert("Couldn't regenerate", isPresented: $showRegenerateError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(regenerateErrorMessage)
        }
        .sheet(isPresented: $showPaywall) { PaywallView(surface: .truncation) }
        .sheet(item: $sourceCard) { card in
            CardSourceSheet(card: card, document: draft.document)
        }
        .sheet(isPresented: $showSave) {
            SaveDraftSheet(draft: draft, cards: validCards, savedSets: studyViewModel.savedSets, onSaved: finishSave)
        }
    }

    private var validCards: [StudyCard] {
        draft.cards.filter {
            !$0.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var headerSummary: String {
        let summary = String(localized: "\(draft.cards.count) cards from \(draft.document.title)")
        guard let pages = draft.pageRangeLabel else { return summary }
        return String(localized: "\(summary), \(pages)")
    }

    private var hasUnsavedEdits: Bool {
        draft.cards != lastGeneratedCards
    }

    private var regenerateErrorMessage: String {
        let base = studyViewModel.generationErrorMessage ?? String(localized: "Your current draft is unchanged. Try again in a moment.")
        guard let code = studyViewModel.generationErrorCode else { return base }
        return String(localized: "\(base) · \(code)")
    }

    private func announce(_ message: String) {
        var text = AttributedString(message)
        text.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(text).post()
    }

    private func removeCard(_ id: UUID) {
        guard let index = draft.cards.firstIndex(where: { $0.id == id }) else { return }
        let neighborID = draft.cards.indices.contains(index + 1)
            ? draft.cards[index + 1].id
            : (index > 0 ? draft.cards[index - 1].id : nil)
        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
            lastRemoval = (draft.cards[index], index)
            draft.remove(id)
        }
        let remaining = draft.cards.count
        announce(String(localized: "Card deleted. \(remaining) cards left"))
        if let neighborID {
            accessibilityFocusedCardID = neighborID
        } else {
            isHeaderFocused = true
        }
    }

    private func undoRemoval() {
        guard let removal = lastRemoval else { return }
        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
            draft.cards.insert(removal.card, at: min(removal.index, draft.cards.count))
            lastRemoval = nil
        }
        accessibilityFocusedCardID = removal.card.id
        announce(String(localized: "Card restored"))
    }

    private func finishSave() {
        isFinished = true
        didSave = true
        showSave = false
        finish()
    }

    private func discard() {
        isFinished = true
        finish()
    }

    // Dismiss before clearing: clearing first empties the sheet while it is still on screen.
    private func finish() {
        dismiss()
        draftStore.set(nil)
    }

    // Once saved or discarded, a late edit or regeneration must not write the draft back.
    private func persistDraft() {
        guard !isFinished else { return }
        draftStore.set(draft)
    }

    private func regenerate() async {
        isRegenerating = true
        defer { isRegenerating = false }
        let cards = await studyViewModel.generateCards(for: draft.document, countsAgainstAllowance: false)
        guard !isFinished else { return }
        guard !cards.isEmpty else {
            showRegenerateError = true
            return
        }
        lastRemoval = nil
        draft.cards = cards
        draft.provenance = studyViewModel.lastGenerationProvenance
        lastGeneratedCards = cards
        persistDraft()
    }
}

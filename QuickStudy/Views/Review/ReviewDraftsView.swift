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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var draft: DraftSet
    @State private var lastGeneratedCards: [StudyCard]
    @State private var isRegenerating = false
    @State private var showRegenerateError = false
    @State private var showRegenerateConfirm = false
    @State private var showPaywall = false
    @State private var lastRemoval: (card: StudyCard, index: Int)?
    @AccessibilityFocusState private var isDraftHeaderFocused: Bool

    private let suggestedTitle: String

    init(draft: DraftSet) {
        _draft = State(initialValue: draft)
        _lastGeneratedCards = State(initialValue: draft.cards)
        suggestedTitle = draft.title
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        TextField("Set title", text: $draft.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        Text("\(draft.pageCount) \(draft.pageCount == 1 ? "page" : "pages") · \(relativeAge)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isRegenerating {
                        ProgressView()
                    } else {
                        Button("Regenerate") {
                            if hasUnsavedEdits {
                                showRegenerateConfirm = true
                            } else {
                                Task { await regenerate() }
                            }
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.appPrimary)
                    }
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                // A row, not the section footer: a plain list pins its footer on an opaque band.
                Text("Tap to edit. Swipe left to remove a card.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } header: {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DRAFT · \(draft.cards.count) CARDS")
                                .foregroundStyle(Color.appPrimary)
                                .accessibilityFocused($isDraftHeaderFocused)
                            Text("From \(draft.title)")
                                .lineLimit(2)
                        }
                    } else {
                        HStack {
                            Text("DRAFT · \(draft.cards.count) CARDS")
                                .foregroundStyle(Color.appPrimary)
                                .accessibilityFocused($isDraftHeaderFocused)
                            Spacer()
                            Text("From \(draft.title)")
                                .lineLimit(1)
                        }
                    }
                }
                .font(.caption)
                .fontWeight(.semibold)
            }
            .listSectionSeparator(.hidden)

            if draft.wasTruncated && !storeController.isPro {
                TruncationNoticeRow { showPaywall = true }
                    .onAppear { analytics.record(.truncationEvent) }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .appTransition(.opacity.combined(with: .move(edge: .top)))
            }

            ForEach($draft.cards) { $card in
                DraftCardRow(card: $card, onRemove: { removeCard(card.id) })
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .appTransition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            removeCard(card.id)
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(BackgroundView())
        .navigationTitle("Draft cards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            if lastRemoval != nil {
                Button(action: undoRemoval) {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .padding(.bottom, Spacing.sm)
                .appTransition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: lastRemoval?.card.id) {
            guard lastRemoval != nil else { return }
            // Cancellation means a newer removal or an undo already replaced this one.
            do { try await Task.sleep(for: .seconds(5)) } catch { return }
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                lastRemoval = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: save) {
                    Text(saveLabel)
                        .contentTransition(.numericText(value: Double(validCards.count)))
                }
                .appAnimation(Motion.snappy, value: validCards.count)
                .disabled(!canSave)
            }
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: draft.cards.count) { old, new in new < old }
        .sensoryFeedback(.success, trigger: draftStore.pending?.id) { old, new in old != nil && new == nil }
        .onChange(of: draft.cards) { _, _ in draftStore.set(draft) }
        .onChange(of: draft.title) { _, _ in draftStore.set(draft) }
        .confirmationDialog(
            "Replace \(draft.cards.count) \(draft.cards.count == 1 ? "card" : "cards")?",
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
    }

    private var validCards: [StudyCard] {
        draft.cards.filter {
            !$0.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var canSave: Bool {
        !validCards.isEmpty
    }

    private var saveLabel: String {
        let count = validCards.count
        return count == 1 ? "Save 1 card" : "Save \(count) cards"
    }

    private var hasUnsavedEdits: Bool {
        draft.cards != lastGeneratedCards
    }

    private var regenerateErrorMessage: String {
        let base = studyViewModel.generationErrorMessage ?? "Your current draft is unchanged. Try again in a moment."
        guard let code = studyViewModel.generationErrorCode else { return base }
        return "\(base) · \(code)"
    }

    private var relativeAge: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: draft.createdAt, relativeTo: Date())
    }

    private func removeCard(_ id: UUID) {
        guard let index = draft.cards.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
            lastRemoval = (draft.cards[index], index)
            draft.remove(id)
        }
        isDraftHeaderFocused = true
    }

    private func undoRemoval() {
        guard let removal = lastRemoval else { return }
        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
            draft.cards.insert(removal.card, at: min(removal.index, draft.cards.count))
            lastRemoval = nil
        }
    }

    /// The title is edited in place at the top of the list; clearing it falls back to the
    /// title generation suggested rather than saving a set with no name.
    private func save() {
        let trimmed = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.title = trimmed.isEmpty ? suggestedTitle : trimmed
        draft.cards = validCards
        studyViewModel.savedSets.insert(draft.committed(), at: 0)
        studyViewModel.saveSavedSets()
        analytics.record(.setCreated)
        draftStore.set(nil)
        dismiss()
    }

    private func regenerate() async {
        isRegenerating = true
        defer { isRegenerating = false }
        let cards = await studyViewModel.generateCards(for: draft.document, countsAgainstAllowance: false)
        guard !cards.isEmpty else {
            showRegenerateError = true
            return
        }
        lastRemoval = nil
        draft.cards = cards
        draft.provenance = studyViewModel.lastGenerationProvenance
        lastGeneratedCards = cards
        draftStore.set(draft)
    }
}

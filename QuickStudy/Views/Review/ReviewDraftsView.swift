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

    @State private var draft: DraftSet
    @State private var lastGeneratedCards: [StudyCard]
    @State private var isRegenerating = false
    @State private var showRegenerateError = false
    @State private var showRegenerateConfirm = false
    @State private var showPaywall = false
    @State private var showNamePrompt = false
    @State private var nameEntry = ""
    @AccessibilityFocusState private var isDraftHeaderFocused: Bool

    init(draft: DraftSet) {
        _draft = State(initialValue: draft)
        _lastGeneratedCards = State(initialValue: draft.cards)
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
            } footer: {
                Text("Tap to edit. Swipe left to remove a card.")
                    .font(.caption)
            }

            if draft.wasTruncated && !storeController.isPro {
                TruncationNoticeRow { showPaywall = true }
                    .onAppear { analytics.record(.truncationEvent) }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }

            ForEach($draft.cards) { $card in
                DraftCardRow(card: $card, onRemove: { removeCard(card.id) })
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(saveLabel) {
                    nameEntry = ""
                    showNamePrompt = true
                }
                .disabled(!canSave)
            }
        }
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
        // The field starts empty with the suggestion as its placeholder, so "Keep
        // suggestion" skips naming and "Save" with nothing typed falls back to it too.
        .alert("Name this set", isPresented: $showNamePrompt) {
            TextField(draft.title, text: $nameEntry)
            Button("Keep suggestion") { save(named: draft.title) }
            Button("Save") { save(named: nameEntry) }
        } message: {
            Text("You can rename it later from your Library.")
        }
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
        draft.remove(id)
        isDraftHeaderFocused = true
    }

    private func save(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { draft.title = trimmed }
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
        draft.cards = cards
        draft.provenance = studyViewModel.lastGenerationProvenance
        lastGeneratedCards = cards
        draftStore.set(draft)
    }
}

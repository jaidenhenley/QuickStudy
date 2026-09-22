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

    @State private var draft: DraftSet
    @State private var isRegenerating = false
    @State private var showRegenerateError = false
    @State private var showPaywall = false

    init(draft: DraftSet) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text")
                        .font(.title3)
                        .foregroundStyle(Color.appPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(draft.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        Text("\(draft.pageCount) \(draft.pageCount == 1 ? "page" : "pages") · \(relativeAge)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isRegenerating {
                        ProgressView()
                    } else {
                        Button("Regenerate") {
                            Task { await regenerate() }
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
                HStack {
                    Text("DRAFT · \(draft.cards.count) CARDS")
                        .foregroundStyle(Color.appPrimary)
                    Spacer()
                    Text("From \(draft.title)")
                        .lineLimit(1)
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
                DraftCardRow(card: $card)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            draft.remove(card.id)
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
                Button("Save") { save() }
                    .disabled(draft.cards.isEmpty)
            }
        }
        .onChange(of: draft.cards) { _, _ in draftStore.set(draft) }
        .alert("Couldn't regenerate", isPresented: $showRegenerateError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(regenerateErrorMessage)
        }
        .sheet(isPresented: $showPaywall) { PaywallView(surface: .truncation) }
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

    private func save() {
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
        draftStore.set(draft)
    }
}

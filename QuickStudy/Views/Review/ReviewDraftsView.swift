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
    @Environment(\.dismiss) private var dismiss

    @State private var draft: DraftSet
    @State private var isRegenerating = false

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
    }

    private var relativeAge: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: draft.createdAt, relativeTo: Date())
    }

    private func save() {
        studyViewModel.savedSets.insert(draft.committed(), at: 0)
        studyViewModel.saveSavedSets()
        draftStore.set(nil)
        dismiss()
    }

    private func regenerate() async {
        isRegenerating = true
        defer { isRegenerating = false }
        let cards = await studyViewModel.generateCards(for: draft.document, countsAgainstAllowance: false)
        guard !cards.isEmpty else { return }
        draft.cards = cards
        draftStore.set(draft)
    }
}

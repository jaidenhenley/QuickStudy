//
//  TypeCardsView.swift
//  QuickStudy
//

import SwiftUI

struct TypeCardsView: View {
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = TypeCardsViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    TextField("Set title", text: $viewModel.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(Spacing.base)
                        .appGlassCard(cornerRadius: AppRadius.lg)

                    ForEach(Array($viewModel.entries.enumerated()), id: \.element.id) { index, $entry in
                        TypeCardRow(
                            index: index + 1,
                            entry: $entry,
                            canRemove: viewModel.entries.count > 1,
                            onRemove: { viewModel.removeEntry(id: entry.id) }
                        )
                    }

                    Button {
                        viewModel.addEntry()
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus")
                            Text("Add another card")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(.plain)
                    .appGlassCard(cornerRadius: AppRadius.md)

                    if viewModel.wantsMoreCards {
                        Text("Four or more cards make better quiz questions — each card's answer becomes a wrong option for the others.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.lg)
            }
            .background(BackgroundView())
            .navigationTitle("Type cards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.saveLabel) {
                        studyViewModel.savedSets.insert(viewModel.makeSet(), at: 0)
                        studyViewModel.saveSavedSets()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

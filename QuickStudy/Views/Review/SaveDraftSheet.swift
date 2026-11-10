//
//  SaveDraftSheet.swift
//  QuickStudy
//

import SwiftUI

struct SaveDraftSheet: View {
    let onSaved: () -> Void

    @State private var viewModel: SaveDraftViewModel
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(draft: DraftSet, cards: [StudyCard], savedSets: [StudySet], onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        _viewModel = State(initialValue: SaveDraftViewModel(draft: draft, cards: cards, savedSets: savedSets))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Picker("Save to", selection: $viewModel.destination) {
                            Text("New Set")
                                .tag(SaveDraftViewModel.Destination.newSet)
                            Text("Add to Existing")
                                .tag(SaveDraftViewModel.Destination.existingSet)
                                .disabled(!viewModel.canAddToExisting)
                        }
                        .pickerStyle(.segmented)

                        if !viewModel.canAddToExisting {
                            Text("You have no sets of your own to add these cards to yet.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Spacing.base)
                        }
                    }

                    switch viewModel.destination {
                    case .newSet:
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("NAME")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                                .tracking(1)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.horizontal, Spacing.base)

                            HStack(spacing: Spacing.xs) {
                                TextField("Set name", text: $viewModel.name)
                                    .font(.body)
                                    .submitLabel(.done)
                                    .accessibilityLabel("Name")
                                if !viewModel.name.isEmpty {
                                    Button("Clear Name", systemImage: "xmark.circle.fill") {
                                        viewModel.name = ""
                                    }
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.secondary)
                                    .frame(minWidth: 44, minHeight: 44)
                                    .contentShape(.rect)
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(minHeight: 44)
                            .padding(.leading, Spacing.base)
                            .padding(.trailing, Spacing.xs)
                            .padding(.vertical, Spacing.xs)
                            .appGlassCard(cornerRadius: AppRadius.md)

                            Text("Suggested from your notes. You can rename it anytime.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Spacing.base)
                        }

                    case .existingSet:
                        if viewModel.canAddToExisting {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.existingSets) { set in
                                        ExistingSetRow(set: set, isSelected: viewModel.selectedSetID == set.id) {
                                            viewModel.selectedSetID = set.id
                                        }
                                        if set.id != viewModel.existingSets.last?.id {
                                            Divider().padding(.leading, Spacing.base)
                                        }
                                    }
                                }
                                .appGlassCard(cornerRadius: AppRadius.lg)

                                Text(viewModel.addFooter)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, Spacing.base)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.vertical, Spacing.sm)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .background(BackgroundView())
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark") {
                        viewModel.save(to: studyViewModel, analytics: analytics)
                        onSaved()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryFill)
                    .disabled(!viewModel.canSave)
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

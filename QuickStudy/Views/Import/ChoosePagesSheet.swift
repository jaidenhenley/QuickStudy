//
//  ChoosePagesSheet.swift
//  QuickStudy
//

import PDFKit
import SwiftUI

struct ChoosePagesSheet: View {
    let onDraft: ([Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ChoosePagesViewModel

    init(fileName: String, document: PDFDocument, onDraft: @escaping ([Int]) -> Void) {
        self.onDraft = onDraft
        _viewModel = State(initialValue: ChoosePagesViewModel(fileName: fileName, document: document))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.base) {
                    VStack(spacing: Spacing.xs) {
                        Text(viewModel.subtitle)
                        Text("Tap pages to choose up to 10.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: 3), spacing: Spacing.base) {
                        ForEach(0..<viewModel.pageCount, id: \.self) { index in
                            PageThumbnailCell(pageIndex: index, viewModel: viewModel) {
                                viewModel.toggle(index)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.sm)
            }
            .contentMargins(.bottom, Spacing.base, for: .scrollContent)
            .background(BackgroundView())
            .navigationTitle("Choose Pages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                VStack(spacing: Spacing.sm) {
                    if viewModel.showsCapNote {
                        Text("You can choose up to 10 pages.")
                            .font(.footnote)
                            .foregroundStyle(Theme.warning)
                            .transition(.opacity)
                    }
                    Text(viewModel.summary)
                        .font(.headline)
                    Text(viewModel.estimate)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button {
                        onDraft(viewModel.sortedSelection)
                        dismiss()
                    } label: {
                        Text(viewModel.buttonTitle)
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonBorderShape(.capsule)
                    .appProminentButtonStyle(tint: Theme.primaryFill)
                    .disabled(!viewModel.canDraft)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.lg)
                .padding(.bottom, Spacing.sm)
                .frame(maxWidth: .infinity)
                .animation(.default, value: viewModel.showsCapNote)
            }
            .sensoryFeedback(.warning, trigger: viewModel.capWarningCount)
        }
    }
}

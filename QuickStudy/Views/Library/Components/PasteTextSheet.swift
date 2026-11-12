//
//  PasteTextSheet.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct PasteTextSheet: View {
    let onSubmit: (String) -> Void

    @Environment(AISettings.self) private var aiSettings
    @Environment(StoreController.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var text: String
    @AccessibilityFocusState private var editorFocused: Bool

    init(initialText: String = "", onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        _text = State(initialValue: initialText)
    }

    var body: some View {
        let analysis = ContentAnalysis.immediate(for: text)
        let isEmpty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let summaryLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.sm))

        NavigationStack {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.sm)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .accessibilityLabel("Paste your notes here")
                    .accessibilityFocused($editorFocused)

                if text.isEmpty {
                    Text("Paste your notes here")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(Spacing.base)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, Spacing.base)
            .padding(.top, Spacing.sm)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                summaryLayout {
                    Text(analysis.wordCount > 0 ? "\(analysis.wordCount) words · about \(analysis.estimatedCards) \(analysis.estimatedCards == 1 ? "card" : "cards")" : "")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.updatesFrequently)
                    Spacer(minLength: 0)
                    Label(engineLabel, systemImage: "sparkles")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Theme.aiAccentText)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(Theme.aiAccent.opacity(0.16), in: Capsule())
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity)
            }
            .background(BackgroundView())
            .navigationTitle("Paste Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Draft Cards", systemImage: "checkmark") {
                        let pasted = text
                        dismiss()
                        onSubmit(pasted)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.primaryFill)
                    .disabled(isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear { editorFocused = true }
    }

    private var firstEngine: GenerationProvenance.Engine? {
        AIController.plan(settings: aiSettings, store: store, sourceLength: text.utf16.count).first
    }

    private var engineLabel: String {
        (firstEngine ?? .onDevice).displayName
    }
}

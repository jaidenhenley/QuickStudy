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
    @Environment(TodayViewModel.self) private var todayViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var text: String

    init(initialText: String = "", onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        _text = State(initialValue: initialText)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.md) {
                let analysis = ContentAnalysis.immediate(for: text)

                HStack {
                    Text("Paste notes")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles")
                        Text("\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free left")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.appSecondary)
                }

                Text("Anything — lecture notes, a chapter, a syllabus.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.sm)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                    if text.isEmpty {
                        Text("Paste your notes here")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(Spacing.base)
                            .allowsHitTesting(false)
                    }
                }

                if analysis.wordCount > 0 {
                    Text("\(analysis.wordCount) words")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Spacing.sm) {
                        Text("~\(analysis.estimatedCards) cards")
                        if let language = analysis.language {
                            Text(language)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.xs)
                    .appGlassCard(cornerRadius: AppRadius.sm)
                }

                Button {
                    let pasted = text
                    dismiss()
                    onSubmit(pasted)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "sparkles")
                        Text("Generate cards")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                // Only truthful on-device: an external API means the notes do leave the phone.
                if aiSettings.mode == .onDevice {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "checkmark.shield")
                        Text("On this iPhone · no upload · works offline")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(Spacing.lg)
            .background(BackgroundView())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

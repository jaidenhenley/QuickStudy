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
    @Environment(StoreController.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var text: String
    @State private var appeared = false

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
                            .symbolEffect(.bounce, value: appeared)
                        Text(allowanceLabel)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.appSecondary)
                }

                Text("Anything works: lecture notes, a chapter or a syllabus.")
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
                        Text(analysis.estimatedCardsLabel)
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

                // The promise has to match the engine that will actually run first: Private
                // Cloud Compute or a hosted generation both mean the notes leave the phone.
                if aiSettings.mode == .onDevice {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: footerSymbol)
                        Text(footerText)
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
        .onAppear {
            appeared = true
        }
    }

    private var allowanceLabel: String {
        if todayViewModel.isPro { return "QuickStudy Pro" }
        if todayViewModel.hasOnlyFreeCloudSet { return "1 free cloud set" }
        return "\(todayViewModel.generationsRemaining) of \(todayViewModel.generationsLimit) free left"
    }

    private var firstEngine: GenerationProvenance.Engine? {
        AIController.plan(settings: aiSettings, store: store, sourceLength: text.utf16.count).first
    }

    private var footerSymbol: String {
        switch firstEngine {
        case .privateCloud: return "lock.icloud"
        case .cloud: return "network"
        default: return "checkmark.shield"
        }
    }

    private var footerText: String {
        switch firstEngine {
        case .privateCloud: return "Apple Private Cloud Compute · not stored"
        case .cloud: return "Sent to Claude via QuickStudy's server · deleted within 30 days"
        default: return "On this iPhone · no upload · works offline"
        }
    }
}

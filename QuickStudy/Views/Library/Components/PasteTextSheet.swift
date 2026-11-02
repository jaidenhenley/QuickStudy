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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var text: String
    @State private var appeared = false
    @ScaledMetric(relativeTo: .body) private var editorMaxHeight: CGFloat = 240
    @AccessibilityFocusState private var editorFocused: Bool

    init(initialText: String = "", onSubmit: @escaping (String) -> Void) {
        self.onSubmit = onSubmit
        _text = State(initialValue: initialText)
    }

    var body: some View {
        let stacksVertically = dynamicTypeSize.isAccessibilitySize
        let headerLayout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout())
        let chipLayout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
            : AnyLayout(HStackLayout(spacing: Spacing.sm))
        let analysis = ContentAnalysis.immediate(for: text)

        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        headerLayout {
                            Text("Paste notes")
                                .font(.title2)
                                .fontWeight(.bold)
                                .accessibilityAddTraits(.isHeader)
                            if !stacksVertically { Spacer() }
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .appSymbolBounce(value: appeared)
                                    .accessibilityHidden(true)
                                Text(allowanceLabel)
                            }
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.appSecondary)
                            .accessibilityElement(children: .combine)
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
                                .frame(minHeight: 120, maxHeight: editorMaxHeight)
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

                        if analysis.wordCount > 0 {
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("\(analysis.wordCount) words")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                chipLayout {
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
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(analysisSummary(analysis))
                            .accessibilityAddTraits(.updatesFrequently)
                        }
                    }
                    .padding(Spacing.lg)
                    .frame(minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: Spacing.sm) {
                    Button {
                        let pasted = text
                        dismiss()
                        onSubmit(pasted)
                    } label: {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "sparkles")
                                .accessibilityHidden(true)
                            Text("Generate cards")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .appProminentButtonStyle(tint: Theme.primaryFill)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    // The promise has to match the engine that will actually run first: Private
                    // Cloud Compute or a hosted generation both mean the notes leave the phone.
                    if aiSettings.mode == .onDevice {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Image(systemName: footerSymbol)
                                .accessibilityHidden(true)
                            Text(footerText)
                                .multilineTextAlignment(.center)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .frame(maxWidth: .infinity)
                .background(.bar)
            }
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
            editorFocused = true
        }
    }

    private func analysisSummary(_ analysis: ContentAnalysis) -> String {
        let cards = analysis.estimatedCards == 1 ? "about 1 card" : "about \(analysis.estimatedCards) cards"
        let parts = ["\(analysis.wordCount) words", cards] + (analysis.language.map { [$0] } ?? [])
        return parts.joined(separator: ", ")
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

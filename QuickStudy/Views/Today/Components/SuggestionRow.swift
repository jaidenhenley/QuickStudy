//
//  SuggestionRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct SuggestionRow: View {
    let suggestion: TodayViewModel.GenerationSuggestion

    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(AppState.self) private var appState
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 44.0

    @State private var isGenerating = false
    @State private var showError = false
    @State private var navigateToSet = false

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.md))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        layout {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Color.appPrimary)
                    .frame(width: tileSize, height: tileSize)
                Image(systemName: "sparkles")
                    .foregroundStyle(Theme.onPrimary)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Generate \(suggestion.cardCount) cards on \(suggestion.topic)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Text("From \(suggestion.sourceTitle) · on-device")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            }
            .accessibilityElement(children: .combine)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer()
            }

            Group {
                if isGenerating {
                    ProgressView()
                        .accessibilityLabel("Generating cards")
                        .appTransition(.scale.combined(with: .opacity))
                } else {
                    Button {
                        Task { await generate() }
                    } label: {
                        Text("Yes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appPrimary)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel("Yes, generate cards")
                    .accessibilityInputLabels(["Yes", "Generate cards"])
                    .appTransition(.scale.combined(with: .opacity))
                }
            }
            .appAnimation(Motion.snappy, value: isGenerating)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .alert("Generation Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(studyViewModel.generationErrorMessage ?? "Please try again.")
        }
        .onChange(of: isGenerating) { _, generating in
            if generating {
                AccessibilityNotification.Announcement("Generating cards").post()
            }
        }
        .navigationDestination(isPresented: $navigateToSet) {
            if let set = studyViewModel.savedSets.first(where: { $0.id == suggestion.setID }) {
                StudySetDetailView(set: set)
            }
        }
    }

    private func generate() async {
        isGenerating = true
        await studyViewModel.generateSuggestedCards(
            for: suggestion.setID,
            topic: suggestion.topic,
            count: suggestion.cardCount
        )
        isGenerating = false

        if studyViewModel.generationErrorMessage == nil {
            navigateToSet = true
        } else {
            showError = true
        }
    }
}

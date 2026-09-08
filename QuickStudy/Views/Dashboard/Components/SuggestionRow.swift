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

    @State private var isGenerating = false
    @State private var showError = false
    @State private var navigateToSet = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Color.appPrimary)
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Generate \(suggestion.cardCount) cards on \(suggestion.topic)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                Text("From \(suggestion.sourceTitle) · \(suggestion.engineLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isGenerating {
                ProgressView()
            } else {
                Button("Yes") {
                    Task { await generate() }
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appPrimary)
            }
        }
        .padding(Spacing.base)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
        .alert("Generation Failed", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(studyViewModel.generationErrorMessage ?? "Please try again.")
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

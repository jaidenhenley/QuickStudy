//
//  SessionCompleteView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionCompleteView: View {
    let summary: QuizSessionViewModel.Summary
    let onAgain: () -> Void
    let onDone: () -> Void

    @AccessibilityFocusState private var headlineFocused: Bool
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                HStack {
                    Spacer()
                    Button("Done", action: onDone)
                }

                Image(systemName: "trophy")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.top, Spacing.lg)
                    .accessibilityHidden(true)
                    .symbolEffect(.bounce, value: appeared)

                Text(summary.headline)
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityFocused($headlineFocused)

                Text("Session complete · \(summary.elapsedLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.appStreak)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(summary.streak) day streak")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        if let delta = summary.cardsVsYesterday, delta > 0 {
                            Text("You beat yesterday by \(delta) cards")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .appStagedReveal(0, shown: appeared)

                HStack(spacing: 0) {
                    SessionStatCell(target: summary.cardCount, label: "CARDS")
                    SessionStatCell(target: summary.correctCount, label: "CORRECT")
                    SessionStatCell(target: Int((summary.accuracy * 100).rounded()), suffix: "%", label: "ACCURACY")
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .appStagedReveal(1, shown: appeared)

                if !summary.reinforcement.isEmpty {
                    Text("NEEDS REINFORCEMENT")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.sm)
                        .appStagedReveal(2, shown: appeared)

                    ForEach(Array(summary.reinforcement.enumerated()), id: \.element.id) { index, item in
                        ReinforcementRow(item: item, index: index + 3, appeared: appeared)
                    }
                }

                Button(action: onAgain) {
                    Text("One more session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .padding(.top, Spacing.base)
                .appStagedReveal(3 + summary.reinforcement.count, shown: appeared)
            }
            .padding(Spacing.lg)
        }
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
        .sensoryFeedback(.success, trigger: appeared) { _, new in new }
        .onAppear {
            headlineFocused = true
            appeared = true
        }
    }
}

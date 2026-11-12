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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.base) {
                if summary.hasMoreDue {
                    HStack {
                        Spacer()
                        Button(action: onDone) {
                            Text("Done")
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                        }
                    }
                }

                Image(systemName: "trophy")
                    .font(.largeTitle)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.top, Spacing.lg)
                    .accessibilityHidden(true)
                    .appSymbolBounce(value: appeared)

                Text(summary.headline)
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headlineFocused)

                Text(summary.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(summary.subtitleSpoken)

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.appStreak)
                        .accessibilityHidden(true)
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
                .accessibilityElement(children: .combine)
                .appStagedReveal(0, shown: appeared)

                let statsLayout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(spacing: Spacing.base))
                    : AnyLayout(HStackLayout(spacing: 0))

                statsLayout {
                    SessionStatCell(
                        target: summary.cardCount,
                        label: LocalizedStringResource("sessionStat.cards", defaultValue: "CARDS", comment: "Session Complete stat: cards studied."),
                        spokenLabel: LocalizedStringResource("sessionStat.cards.spoken", defaultValue: "Cards", comment: "Spoken name of the cards-studied stat.")
                    )
                    SessionStatCell(
                        target: summary.correctCount,
                        label: LocalizedStringResource("sessionStat.correct", defaultValue: "CORRECT", comment: "Session Complete stat: how many answers were right."),
                        spokenLabel: LocalizedStringResource("sessionStat.correct.spoken", defaultValue: "Correct", comment: "Spoken name of the right-answers count.")
                    )
                    SessionStatCell(
                        target: Int((summary.accuracy * 100).rounded()),
                        isPercent: true,
                        label: LocalizedStringResource("sessionStat.accuracy", defaultValue: "ACCURACY", comment: "Session Complete stat: share of answers that were right."),
                        spokenLabel: LocalizedStringResource("sessionStat.accuracy.spoken", defaultValue: "Accuracy", comment: "Spoken name of the accuracy stat.")
                    )
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
                        .accessibilityAddTraits(.isHeader)
                        .appStagedReveal(2, shown: appeared)

                    ForEach(Array(summary.reinforcement.enumerated()), id: \.element.id) { index, item in
                        ReinforcementRow(item: item, index: index + 3, appeared: appeared)
                    }
                }
            }
            .padding(Spacing.lg)
            .appReadableWidth()
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaInset(edge: .bottom) {
            Button(action: summary.hasMoreDue ? onAgain : onDone) {
                Text(summary.hasMoreDue ? String(localized: "One more session") : String(localized: "Done"))
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primaryFill)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.base)
            .appReadableWidth()
        }
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
        .sensoryFeedback(.success, trigger: appeared) { _, new in new }
        .task {
            await Task.yield()
            headlineFocused = true
        }
        .onAppear { appeared = true }
    }
}

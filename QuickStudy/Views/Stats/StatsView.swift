//
//  StatsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct StatsView: View {
    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var statsViewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.base) {
                if !statsViewModel.hasData {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "chart.bar")
                            .font(.largeTitle)
                            .foregroundStyle(Color.appPrimary)
                            .accessibilityHidden(true)
                        Text("No stats yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        Text("Save a set to start tracking your progress.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xl)
                } else {
                    GlassEffectContainer {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: Spacing.md),
                                GridItem(.flexible(), spacing: Spacing.md)
                            ],
                            spacing: Spacing.md
                        ) {
                            StatTile(value: "\(statsViewModel.streak)", label: "Day streak", tint: .appStreak)
                            StatTile(value: "\(statsViewModel.dueToday)", label: "Cards due today")
                            StatTile(value: "\(statsViewModel.masteredCards)", label: "Cards mastered", tint: Theme.successText)
                            StatTile(value: "\(statsViewModel.scheduledCards)", label: "Cards in rotation")
                        }
                    }

                    Text("OVERALL PROGRESS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.top, Spacing.sm)
                        .accessibilityAddTraits(.isHeader)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(statsViewModel.overallProgress.formatted(.percent.precision(.fractionLength(0))))
                            .font(.title2)
                            .fontWeight(.bold)
                            .appNumericTransition(value: statsViewModel.overallProgress * 100)
                        ProgressView(value: statsViewModel.overallProgress)
                            .tint(Color.appPrimary)
                            .appAnimation(Motion.standard, value: statsViewModel.overallProgress)
                        Text("Across \(statsViewModel.setCount) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.base)
                    .appGlassCard(cornerRadius: AppRadius.lg)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Overall progress")
                    .accessibilityValue(String(localized: "\(Int((statsViewModel.overallProgress * 100).rounded())) percent, across \(statsViewModel.setCount) sets"))

                    if !statsViewModel.toughest.isEmpty {
                        Text("TOUGHEST CARDS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.top, Spacing.sm)
                            .accessibilityAddTraits(.isHeader)

                        ForEach(statsViewModel.toughest) { card in
                            StatToughCardRow(card: card)
                                .appTransition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    Text("BY SET")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.top, Spacing.sm)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(statsViewModel.setProgress) { entry in
                        StatSetRow(entry: entry)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
            .appReadableWidth(alignment: .leading)
        }
        .background(BackgroundView())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                statsViewModel.update(from: studyViewModel.savedSets, sessions: sessionStore)
            }
        }
        .onChange(of: studyViewModel.savedSets) { _, _ in
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                statsViewModel.update(from: studyViewModel.savedSets, sessions: sessionStore)
            }
        }
    }
}

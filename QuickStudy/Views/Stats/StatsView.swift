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

    @State private var statsViewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.base) {
                if !statsViewModel.hasData {
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "chart.bar")
                            .font(.largeTitle)
                            .foregroundStyle(Color.appPrimary)
                        Text("No stats yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Approve some cards and finish a session to start tracking your progress.")
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
                            StatTile(value: "\(statsViewModel.streak)", label: "Day streak", tint: .orange)
                            StatTile(value: "\(statsViewModel.dueToday)", label: "Cards due today")
                            StatTile(value: "\(statsViewModel.masteredCards)", label: "Cards mastered", tint: Theme.success)
                            StatTile(value: "\(statsViewModel.scheduledCards)", label: "Cards in rotation")
                        }
                    }

                    Text("OVERALL PROGRESS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.top, Spacing.sm)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("\(Int((statsViewModel.overallProgress * 100).rounded()))%")
                            .font(.title2)
                            .fontWeight(.bold)
                        ProgressView(value: statsViewModel.overallProgress)
                            .tint(Color.appPrimary)
                        Text("Across \(statsViewModel.setCount) \(statsViewModel.setCount == 1 ? "set" : "sets")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(Spacing.base)
                    .appGlassCard(cornerRadius: AppRadius.lg)

                    if !statsViewModel.toughest.isEmpty {
                        Text("TOUGHEST CARDS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                            .padding(.top, Spacing.sm)

                        ForEach(statsViewModel.toughest) { card in
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppRadius.sm)
                                        .fill(Theme.danger.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Text("\(card.missCount)×")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Theme.danger)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(card.question)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                    Text(card.setTitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(Spacing.base)
                            .appGlassCard(cornerRadius: AppRadius.lg)
                        }
                    }

                    Text("BY SET")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .tracking(1)
                        .padding(.top, Spacing.sm)

                    ForEach(statsViewModel.setProgress) { entry in
                        StatSetRow(entry: entry)
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .background(BackgroundView())
        .navigationTitle("Stats")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { statsViewModel.update(from: studyViewModel.savedSets, sessions: sessionStore) }
        .onChange(of: studyViewModel.savedSets) { _, _ in
            statsViewModel.update(from: studyViewModel.savedSets, sessions: sessionStore)
        }
    }
}

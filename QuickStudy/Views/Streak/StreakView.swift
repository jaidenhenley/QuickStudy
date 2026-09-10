//
//  StreakView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct StreakView: View {
    @Environment(SessionStore.self) private var sessionStore

    private let weekdayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        let summary = StreakCalculator.summary(
            studiedDays: sessionStore.studiedDays(),
            frozenDays: StreakStore.frozenDays
        )

        ScrollView {
            VStack(spacing: Spacing.base) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.18))
                        .frame(width: 76, height: 76)
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.orange)
                }
                .padding(.top, Spacing.lg)

                Text("\(summary.current) \(summary.current == 1 ? "day" : "days")")
                    .font(.system(size: 44, weight: .bold))

                Text(subtitle(for: summary))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 0) {
                    ForEach(summary.week.indices, id: \.self) { index in
                        StreakDayDot(
                            letter: weekdayLetters[index % weekdayLetters.count],
                            state: summary.week[index]
                        )
                    }
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)

                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: "snowflake")
                        .foregroundStyle(Color.appSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.appSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(freezeTitle(for: summary))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Auto-applies if you miss a day. Earn one per full study week.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
            }
            .padding(Spacing.lg)
        }
        .background(BackgroundView())
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subtitle(for summary: StreakSummary) -> String {
        if summary.current == 0 {
            return "Finish a session to start a streak."
        }
        if summary.current >= summary.longest {
            return "Longest yet"
        }
        return "Longest was \(summary.longest)"
    }

    private func freezeTitle(for summary: StreakSummary) -> String {
        summary.freezesAvailable == 0
            ? "No Streak Freeze yet"
            : "\(summary.freezesAvailable) Streak \(summary.freezesAvailable == 1 ? "Freeze" : "Freezes") ready"
    }
}

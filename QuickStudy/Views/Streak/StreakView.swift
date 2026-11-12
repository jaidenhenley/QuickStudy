//
//  StreakView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct StreakView: View {
    @Environment(SessionStore.self) private var sessionStore
    @ScaledMetric(relativeTo: .largeTitle) private var flameBadgeSize = 76
    @ScaledMetric(relativeTo: .subheadline) private var freezeIconSize = 32

    private let weekdayLetters = StreakView.mondayFirst(Calendar.current.veryShortStandaloneWeekdaySymbols)
    private let weekdayNames = StreakView.mondayFirst(Calendar.current.standaloneWeekdaySymbols)

    var body: some View {
        let summary = StreakCalculator.summary(
            studiedDays: sessionStore.studiedDays(),
            frozenDays: StreakStore.frozenDays
        )

        ScrollView {
            VStack(spacing: Spacing.base) {
                ZStack {
                    Circle()
                        .fill(Color.appStreak.opacity(0.18))
                        .frame(width: flameBadgeSize, height: flameBadgeSize)
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundStyle(.appStreak)
                        .appSymbolPulse(options: .nonRepeating, value: summary.current)
                }
                .accessibilityHidden(true)
                .padding(.top, Spacing.lg)

                VStack(spacing: Spacing.base) {
                    Text("\(summary.current) days")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .appNumericTransition(value: Double(summary.current))
                        .appAnimation(Motion.snappy, value: summary.current)
                        .accessibilityAddTraits(.isHeader)

                    Text(subtitle(for: summary))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(spokenSubtitle(for: summary))
                }
                .accessibilityElement(children: .combine)

                HStack(spacing: 0) {
                    ForEach(summary.week.indices, id: \.self) { index in
                        StreakDayDot(
                            letter: weekdayLetters[index % weekdayLetters.count],
                            dayName: weekdayNames[index % weekdayNames.count],
                            state: summary.week[index]
                        )
                    }
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("This week")

                HStack(alignment: .top, spacing: Spacing.md) {
                    Image(systemName: "snowflake")
                        .foregroundStyle(Color.appSecondary)
                        .frame(width: freezeIconSize, height: freezeIconSize)
                        .background(Color.appSecondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(freezeTitle(for: summary))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .appNumericTransition(value: Double(summary.freezesAvailable))
                        Text("Auto-applies if you miss a day. Earn one per full study week.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg)
                .accessibilityElement(children: .combine)
            }
            .padding(Spacing.lg)
            .appReadableWidth()
        }
        .background(BackgroundView())
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subtitle(for summary: StreakSummary) -> String {
        if summary.current == 0 {
            return String(localized: "Finish a session to start a streak.")
        }
        if summary.current >= summary.longest {
            return String(localized: "Longest yet")
        }
        return String(localized: "Longest was \(summary.longest)")
    }

    private func spokenSubtitle(for summary: StreakSummary) -> String {
        if summary.current == 0 || summary.current >= summary.longest {
            return subtitle(for: summary)
        }
        return String(localized: "Longest streak was \(summary.longest) days")
    }

    private func freezeTitle(for summary: StreakSummary) -> String {
        summary.freezesAvailable == 0
            ? String(localized: "No Streak Freeze yet")
            : String(localized: "\(summary.freezesAvailable) Streak Freezes ready")
    }

    private static func mondayFirst(_ sundayFirst: [String]) -> [String] {
        Array(sundayFirst.dropFirst()) + sundayFirst.prefix(1)
    }
}

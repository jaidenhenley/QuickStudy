//
//  StreakDayDot.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct StreakDayDot: View {
    let letter: String
    let dayName: String
    let state: StreakSummary.DayState

    @ScaledMetric(relativeTo: .caption) private var dotSize = 32

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: min(dotSize, 44), height: min(dotSize, 44))
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption)
                        .foregroundStyle(tint)
                        .appSymbolReplaceTransition()
                        .appSymbolBounce(value: state)
                }
            }
            .appAnimation(Motion.snappy, value: state)
            Text(letter)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(dayName)
        .accessibilityValue(accessibilityValue)
    }

    private var symbol: String? {
        switch state {
        case .studied: return "flame.fill"
        case .frozen: return "snowflake"
        case .today: return "circle"
        case .missed: return "xmark"
        case .future: return nil
        }
    }

    private var accessibilityValue: String {
        switch state {
        case .studied: return String(localized: "studied")
        case .frozen: return String(localized: "freeze used")
        case .today: return String(localized: "today")
        case .missed: return String(localized: "missed")
        case .future: return String(localized: "upcoming")
        }
    }

    private var tint: Color {
        switch state {
        case .studied: return .appStreak
        case .frozen: return Color.appSecondary
        default: return .secondary
        }
    }

    private var fill: Color {
        switch state {
        case .studied: return .appStreak.opacity(0.18)
        case .frozen: return Color.appSecondary.opacity(0.18)
        case .today: return Color.appPrimary.opacity(0.18)
        case .missed, .future: return Theme.chipFill
        }
    }
}

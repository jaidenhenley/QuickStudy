//
//  StreakDayDot.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct StreakDayDot: View {
    let letter: String
    let state: StreakSummary.DayState

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle()
                    .fill(fill)
                    .frame(width: 32, height: 32)
                if let symbol {
                    Image(systemName: symbol)
                        .font(.caption)
                        .foregroundStyle(tint)
                }
            }
            Text(letter)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var symbol: String? {
        switch state {
        case .studied: return "flame.fill"
        case .frozen: return "snowflake"
        case .missed, .today, .future: return nil
        }
    }

    private var tint: Color {
        switch state {
        case .studied: return .orange
        case .frozen: return Color.appSecondary
        default: return .secondary
        }
    }

    private var fill: Color {
        switch state {
        case .studied: return .orange.opacity(0.18)
        case .frozen: return Color.appSecondary.opacity(0.18)
        case .today: return Color.appPrimary.opacity(0.18)
        case .missed, .future: return Color.secondary.opacity(0.12)
        }
    }
}

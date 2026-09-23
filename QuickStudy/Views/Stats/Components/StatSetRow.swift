//
//  StatSetRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct StatSetRow: View {
    let entry: StatsViewModel.SetProgress
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                Spacer()
                if entry.mastery == .mastered {
                    Text("Mastered")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.successText)
                } else {
                    Text("\(Int((entry.progress * 100).rounded()))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: entry.progress)
                .tint(entry.mastery == .mastered ? Theme.success : Color.appPrimary)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.title)
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        if entry.mastery == .mastered {
            return "Mastered"
        } else {
            let percent = Int((entry.progress * 100).rounded())
            return "\(percent) percent"
        }
    }
}

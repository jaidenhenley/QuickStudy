//
//  StatToughCardRow.swift
//  QuickStudy
//

import SwiftUI

struct StatToughCardRow: View {
    let card: StatsViewModel.ToughCard

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var badgeSize = 36

    var body: some View {
        HStack {
            Text("\(card.missCount)×")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(Theme.dangerText)
                .frame(width: badgeSize, height: badgeSize)
                .background(Theme.danger.opacity(0.15), in: RoundedRectangle(cornerRadius: AppRadius.sm))
            VStack(alignment: .leading, spacing: 2) {
                Text(card.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                Text(card.setTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(card.question)
        .accessibilityValue("\(card.setTitle), missed \(card.missCount) \(card.missCount == 1 ? "time" : "times")")
    }
}

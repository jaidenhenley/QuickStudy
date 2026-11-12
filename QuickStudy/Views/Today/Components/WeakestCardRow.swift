//
//  WeakestCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct WeakestCardRow: View {
    let weakest: TodayViewModel.WeakestCardInfo

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var badgeSize = 36.0

    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Theme.danger.opacity(0.15))
                    .frame(width: badgeSize, height: badgeSize)
                Text("\(weakest.missCount)×")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.dangerText)
                    .appNumericTransition()
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(weakest.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                Text("Missed \(weakest.missCount) times · Drill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
    }
}

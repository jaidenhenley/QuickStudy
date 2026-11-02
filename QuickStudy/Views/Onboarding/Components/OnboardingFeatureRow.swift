//
//  OnboardingFeatureRow.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingFeatureRow: View {
    let symbol: String
    let title: String
    let detail: String

    @ScaledMetric(relativeTo: .headline) private var iconWidth = 28

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.appPrimary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

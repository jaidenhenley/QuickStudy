//
//  OnboardingStepRow.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingStepRow: View {
    let number: Int
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    @ScaledMetric(relativeTo: .headline) private var badgeSize = 36

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.appPrimary)
                .frame(width: badgeSize, height: badgeSize)
                .background(Color.appPrimary.opacity(0.12), in: Circle())

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

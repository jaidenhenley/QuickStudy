//
//  OnboardingSourceRow.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingSourceRow: View {
    let symbol: String
    let title: String
    let detail: String
    let action: () -> Void

    @ScaledMetric(relativeTo: .headline) private var tileSize = 40

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Image(systemName: symbol)
                    .font(.headline)
                    .foregroundStyle(.appPrimary)
                    .frame(width: tileSize, height: tileSize)
                    .background(Color.appPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: AppRadius.sm))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .appGlassCard(cornerRadius: AppRadius.lg)
        }
        .buttonStyle(.plain)
    }
}

//
//  WhatsNewProCard.swift
//  QuickStudy
//

import SwiftUI

struct WhatsNewProCard: View {
    let feature: ReleaseNote.Feature
    let onSeePro: () -> Void

    @ScaledMetric(relativeTo: .headline) private var iconWidth = 28.0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.base) {
                Image(systemName: feature.symbol)
                    .font(.headline)
                    .foregroundStyle(.appAIAccent)
                    .frame(width: iconWidth)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(feature.title)
                        .font(.headline)
                    Text(feature.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            Button(action: onSeePro) {
                Text("See QuickStudy Pro")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.aiAccent)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appAIAccent.opacity(0.18))
    }
}

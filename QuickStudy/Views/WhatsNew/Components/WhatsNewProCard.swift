//
//  WhatsNewProCard.swift
//  QuickStudy
//

import SwiftUI

struct WhatsNewProCard: View {
    let feature: ReleaseNote.Feature
    let onSeePro: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.base) {
                Image(systemName: feature.symbol)
                    .font(.headline)
                    .foregroundStyle(.appAIAccent)
                    .frame(width: 28)
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

//
//  AddCardsSection.swift
//  QuickStudy
//

import SwiftUI

struct AddCardsSection: View {
    let onTypeCards: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("ADD CARDS")
                .font(.caption)
                .fontWeight(.semibold)
                .tracking(1)
                .foregroundStyle(.secondary)

            Button(action: onTypeCards) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "text.alignleft")
                        .font(.subheadline)
                        .foregroundStyle(Theme.primary)
                        .frame(width: 36, height: 36)
                        .background(Theme.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Type cards")
                            .font(.headline)
                        Text("Quick two-field editor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(Spacing.md)
            }
            .buttonStyle(.plain)
            .appGlassCard(cornerRadius: AppRadius.lg)

            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("AI card generation needs an iPhone with Apple Intelligence (iPhone 15 Pro or later). Everything else — sets, sessions, streaks — works fully on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .appGlassCard(cornerRadius: AppRadius.md)
        }
    }
}

//
//  AddCardsSection.swift
//  QuickStudy
//

import SwiftUI

struct AddCardsSection: View {
    let reason: LibraryViewModel.AddCardsReason
    let onTypeCards: () -> Void
    let onUpgrade: () -> Void

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

            Button(action: onUpgrade) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(Theme.aiAccentText)
                        .frame(width: 36, height: 36)
                        .background(Color.appAIAccent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Go Pro for AI generation")
                            .font(.headline)
                        Text(upgradeSubtitle)
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
                Text(infoText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .appGlassCard(cornerRadius: AppRadius.md)
        }
    }

    private var upgradeSubtitle: String {
        switch reason {
        case .noOnDeviceModel:
            return "Pro generates cards on our server, no Apple Intelligence required"
        case .allowanceExhausted:
            return "Unlock more generations this month"
        }
    }

    private var infoText: String {
        switch reason {
        case .noOnDeviceModel:
            return "AI card generation needs an iPhone with Apple Intelligence (iPhone 15 Pro or later), unless you're on Pro. Everything else — sets, sessions, streaks — works fully on this device."
        case .allowanceExhausted:
            return "You've used this month's free AI generations. Type cards by hand, or go Pro for more."
        }
    }
}

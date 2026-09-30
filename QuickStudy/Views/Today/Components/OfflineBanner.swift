//
//  OfflineBanner.swift
//  QuickStudy
//

import SwiftUI

struct OfflineBanner: View {
    let canSwitchToOnDevice: Bool
    let onOpenSettings: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        Button(action: onOpenSettings) {
            layout {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(Theme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You're offline. Card generation needs a connection.")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.md)
        }
        .buttonStyle(.plain)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }

    private var subtitle: String {
        canSwitchToOnDevice
            ? "Switch to On-Device in Settings to keep generating"
            : "Generation will resume once you're back online"
    }
}

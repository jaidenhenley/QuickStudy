//
//  OfflineBanner.swift
//  QuickStudy
//

import SwiftUI

struct OfflineBanner: View {
    let onOpenSettings: () -> Void

    var body: some View {
        Button(action: onOpenSettings) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "wifi.slash")
                    .font(.subheadline)
                    .foregroundStyle(Theme.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("You're offline — card generation needs a connection")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    Text("Switch to On-Device in Settings to keep generating")
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
}

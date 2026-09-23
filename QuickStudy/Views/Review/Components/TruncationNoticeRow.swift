//
//  TruncationNoticeRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/22/26.
//

import SwiftUI

struct TruncationNoticeRow: View {
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Text("PRO")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(1)
                    .foregroundStyle(Theme.aiAccentText)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.appAIAccent.opacity(0.15), in: Capsule())
                Text("Some sections weren't drafted")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
            }

            // Names the cause — without it the missing cards read as a bug, not a limit.
            Text("Apple Intelligence couldn't process part of this document, so those sections have no cards. Pro drafts with QuickStudy's cloud model instead.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: action) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                    Text("Upgrade to Pro")
                }
                .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appAIAccent.opacity(0.2))
    }
}

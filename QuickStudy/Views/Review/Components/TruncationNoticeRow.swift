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
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 2)
                    .background(Color.appAIAccent, in: Capsule())
                Text("Only the first 1,200 characters were used")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
            }

            // Names the plan as the cause — without it the cut reads as a bug, not a limit.
            Text("The free plan drafts from the start of long notes. Pro reads your whole document, so your cards cover all of it.")
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
            .appProminentButtonStyle(tint: Theme.aiAccent)
            .padding(.top, Spacing.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appAIAccent.opacity(0.2))
    }
}

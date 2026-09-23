//
//  RecoveredDraftRow.swift
//  QuickStudy
//

import SwiftUI

struct RecoveredDraftRow: View {
    let draft: DraftSet
    let onResume: () -> Void

    var body: some View {
        Button(action: onResume) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 36, height: 36)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume \(draft.title)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    Text("\(draft.cards.count) \(draft.cards.count == 1 ? "card" : "cards") drafted · not yet saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Spacing.base)
        }
        .buttonStyle(.plain)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }
}

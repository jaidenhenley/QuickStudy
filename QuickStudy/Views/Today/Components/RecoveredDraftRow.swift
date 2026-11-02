//
//  RecoveredDraftRow.swift
//  QuickStudy
//

import SwiftUI

struct RecoveredDraftRow: View {
    let draft: DraftSet
    let onResume: () -> Void

    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 36.0
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let stacksVertically = dynamicTypeSize.isAccessibilitySize
        let rowLayout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        Button(action: onResume) {
            rowLayout {
                Image(systemName: "doc.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                    .frame(width: tileSize, height: tileSize)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume \(draft.title)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(stacksVertically ? nil : 2)
                    Text("\(draft.cards.count) \(draft.cards.count == 1 ? "card" : "cards") drafted · not yet saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !stacksVertically {
                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.base)
        }
        .buttonStyle(.plain)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Library")
    }
}

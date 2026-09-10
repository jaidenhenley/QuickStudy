//
//  SetTile.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct SetTile: View {
    let set: StudySet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let dueCount = set.dueCount()
            if dueCount > 0 {
                Text("\(dueCount) DUE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text(set.title)
                .font(.headline)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(set.cards.count) cards")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            ProgressView(value: set.progress)
                .tint(set.masteryState == .mastered ? Theme.success : Color.appPrimary)

            if set.masteryState == .mastered {
                Text("Mastered")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.success)
            } else {
                Text("\(Int((set.progress * 100).rounded()))%")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.base)
        .frame(maxWidth: .infinity, minHeight: 152, alignment: .leading)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(set.title), \(set.cards.count) cards")
    }
}

//
//  UpNextRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct UpNextRow: View {
    let entry: TodayViewModel.UpNextEntry

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                Text("\(entry.dayLabel) · \(entry.cardCount) cards")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title), \(entry.dayLabel), \(entry.cardCount) cards")
    }
}

//
//  StatSetRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct StatSetRow: View {
    let entry: StatsViewModel.SetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Spacer()
                if entry.mastery == .mastered {
                    Text("Mastered")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.success)
                } else {
                    Text("\(Int((entry.progress * 100).rounded()))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: entry.progress)
                .tint(entry.mastery == .mastered ? Theme.success : Color.appPrimary)
        }
        .padding(Spacing.base)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

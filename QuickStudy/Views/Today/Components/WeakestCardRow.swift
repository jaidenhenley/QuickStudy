//
//  WeakestCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 5/1/26.
//

import SwiftUI

struct WeakestCardRow: View {
    let weakest: TodayViewModel.WeakestCardInfo

    var body: some View {
        HStack {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(Theme.danger.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(weakest.missCount)×")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.danger)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(weakest.question)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text("Missed \(weakest.missCount) \(weakest.missCount == 1 ? "time" : "times") — drill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }
}

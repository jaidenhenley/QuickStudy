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
        Button(action: action) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.appAIAccent)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Only the first 1,200 characters were used")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                    Text("Generate from the whole document with Pro ›")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.appAIAccent)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.base)
            .appGlassCard(cornerRadius: AppRadius.lg, tint: .appAIAccent)
        }
        .buttonStyle(.plain)
    }
}

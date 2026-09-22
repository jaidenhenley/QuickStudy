//
//  DraftedCardPreview.swift
//  QuickStudy
//

import SwiftUI

struct DraftedCardPreview: View {
    let card: StudyCard
    let position: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                Text("CARD \(position) OF \(total) · DRAFTED")
                    .tracking(0.5)
                Spacer()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.appPrimary)

            Text(card.question)
                .font(.subheadline)
                .fontWeight(.bold)
            Text(card.answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

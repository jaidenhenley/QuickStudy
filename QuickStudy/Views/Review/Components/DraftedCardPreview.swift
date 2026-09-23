//
//  DraftedCardPreview.swift
//  QuickStudy
//

import SwiftUI

struct DraftedCardPreview: View {
    let card: StudyCard
    let position: Int
    let cardCount: Int
    let pageIndex: Int
    let pageCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                Text("CARD \(position) OF \(cardCount) · DRAFTED")
                    .tracking(0.5)
                Spacer()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.appPrimary)

            Text(card.question)
                .font(.subheadline)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.answer)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.sm)

            DeckPageDots(count: pageCount, current: pageIndex)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

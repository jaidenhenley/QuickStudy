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
    let onAdjust: (AccessibilityAdjustmentDirection) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)
                Text("CARD \(position) OF \(cardCount) · DRAFTED")
                    .tracking(0.5)
                    .accessibilityHidden(true)
                Spacer()
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(Color.appPrimary)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(card.question)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(card.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityValue("Card \(position) of \(cardCount)")
                .accessibilityAdjustableAction(onAdjust)
            }
            .scrollBounceBehavior(.basedOnSize)

            PageDots(count: pageCount, current: pageIndex)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

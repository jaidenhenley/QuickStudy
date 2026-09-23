//
//  DraftedDeckSummary.swift
//  QuickStudy
//

import SwiftUI

struct DraftedDeckSummary: View {
    let cardCount: Int
    let pageIndex: Int
    let pageCount: Int
    let onReview: () -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text(cardCount == 1 ? "That's the only card" : "That's all \(cardCount) cards")
                .font(.subheadline)
                .fontWeight(.bold)

            Text("Edit or remove any of them next.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button(action: onReview) {
                Text(cardCount == 1 ? "Review 1 card" : "Review \(cardCount) cards")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .padding(.top, Spacing.xs)

            Spacer(minLength: Spacing.sm)

            DeckPageDots(count: pageCount, current: pageIndex)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

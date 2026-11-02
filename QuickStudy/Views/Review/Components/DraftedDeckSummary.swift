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
    let onAdjust: (AccessibilityAdjustmentDirection) -> Void

    var body: some View {
        VStack(spacing: Spacing.sm) {
            ScrollView {
                VStack(spacing: Spacing.sm) {
                    VStack(spacing: Spacing.xs) {
                        Text(cardCount == 1 ? "That's the only card" : "That's all \(cardCount) cards")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)

                        Text("Edit or remove any of them next.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAdjustableAction(onAdjust)

                    Button(action: onReview) {
                        Text(cardCount == 1 ? "Review 1 card" : "Review \(cardCount) cards")
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .appProminentButtonStyle(tint: Theme.primaryFill)
                    .padding(.top, Spacing.xs)
                }
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)

            PageDots(count: pageCount, current: pageIndex)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

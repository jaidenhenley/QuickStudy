//
//  DraftedCardNavigator.swift
//  QuickStudy
//

import SwiftUI

struct DraftedCardNavigator: View {
    let card: StudyCard
    let position: Int
    let total: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: "sparkles")
                Text("CARD \(position) OF \(total) · DRAFTED")
                    .tracking(0.5)
                Spacer()
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                }
                .disabled(position == 1)
                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                }
                .disabled(position == total)
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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
    }
}

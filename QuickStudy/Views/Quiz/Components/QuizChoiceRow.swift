//
//  QuizChoiceRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct QuizChoiceRow: View {
    let letter: String
    let text: String
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric(relativeTo: .caption) private var chipSize = 26

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(letter)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? Theme.onPrimary : .secondary)
                    .frame(width: chipSize, height: chipSize)
                    .background(isSelected ? Theme.primaryFill : Theme.chipFill)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                // Sized by the semibold rendering so the heavier selected weight can never re-wrap the row.
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .hidden()
                    .overlay(alignment: .topLeading) {
                        Text(text)
                            .font(.subheadline)
                            .fontWeight(isSelected ? .semibold : .regular)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.base)
            .appGlassCard(cornerRadius: AppRadius.lg, tint: isSelected ? Color.appPrimary.opacity(0.35) : nil)
            .appAnimation(Motion.snappy, value: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Option \(letter), \(text)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

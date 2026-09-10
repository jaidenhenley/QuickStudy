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

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(letter)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(isSelected ? Color.white : .secondary)
                    .frame(width: 26, height: 26)
                    .background(isSelected ? Color.appPrimary : Color.secondary.opacity(0.15))
                    .clipShape(Circle())

                Text(text)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? Color.appPrimary : Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Spacing.base)
            .appGlassCard(cornerRadius: AppRadius.lg, tint: isSelected ? Color.appPrimary.opacity(0.35) : nil)
        }
        .buttonStyle(.plain)
    }
}

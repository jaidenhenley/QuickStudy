//
//  ExistingSetRow.swift
//  QuickStudy
//

import SwiftUI

struct ExistingSetRow: View {
    let set: SaveDraftViewModel.ExistingSet
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                Text(set.title)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: Spacing.sm)
                Text(set.countLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.primary)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

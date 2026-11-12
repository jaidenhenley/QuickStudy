//
//  DraftStatusCloseButton.swift
//  QuickStudy
//

import SwiftUI

struct DraftStatusCloseButton: View {
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Theme.chipFill, in: .circle)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.trailing, -Spacing.sm)
        .padding(.top, -Spacing.sm)
        .accessibilityLabel(label)
    }
}

//
//  DraftSourcePill.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/20/26.
//

import SwiftUI

struct DraftSourcePill: View {
    let source: CardSource
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // An explicit stack: inside a List row a Label takes the row's wide icon inset.
            HStack(spacing: Spacing.xs) {
                Image(systemName: "doc.text.magnifyingglass")
                Text(label)
            }
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(Theme.primary.opacity(0.12), in: .capsule)
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint("Shows the passage this card came from")
    }

    private var label: String {
        guard let page = source.page else { return String(localized: "Source") }
        return String(localized: "Source · p.\(page)")
    }

    private var spokenLabel: String {
        guard let page = source.page else { return String(localized: "Source") }
        return String(localized: "Source, page \(page)")
    }
}

//
//  DraftSourcePill.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/20/26.
//

import SwiftUI

struct DraftSourcePill: View {
    let source: CardSource

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "link")
                .accessibilityHidden(true)
            Text(source.shortLabel)
        }
        .font(.caption2)
        .foregroundStyle(Color.appPrimary)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, 3)
        .background(Color.appPrimary.opacity(0.12), in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spokenLabel(for: source))
    }

    static func spokenLabel(for source: CardSource) -> String {
        var parts: [String] = []
        if let page = source.page { parts.append("Page \(page)") }
        if let paragraph = source.paragraph { parts.append("paragraph \(paragraph)") }
        guard !parts.isEmpty else { return "Source: \(source.documentTitle)" }
        return parts.joined(separator: ", ")
    }
}

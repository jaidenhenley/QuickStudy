//
//  SourceRow.swift
//  QuickStudy
//

import SwiftUI

struct SourceRow: View {
    let title: LocalizedStringResource
    let subtitle: LocalizedStringResource
    let systemImage: String
    var tint: Color = Theme.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.md) {
                SourceTile(systemImage: systemImage, tint: tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Theme.textPrimary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.base)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(String(localized: title)), \(String(localized: subtitle))")
        .accessibilityAddTraits(.isButton)
    }
}

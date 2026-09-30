//
//  TypeCardRow.swift
//  QuickStudy
//

import SwiftUI

struct TypeCardRow: View {
    let index: Int
    @Binding var entry: TypeCardsViewModel.Entry
    let canRemove: Bool
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("CARD \(index)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer()
                if canRemove {
                    Button(role: .destructive, action: onRemove) {
                        Image(systemName: "minus.circle")
                            .font(.footnote)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Remove card \(index)")
                }
            }

            TextField("Term", text: $entry.term)
                .font(.headline)

            Divider()

            TextField("Definition", text: $entry.definition, axis: .vertical)
                .font(.subheadline)
                .lineLimit(1...4)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }
}

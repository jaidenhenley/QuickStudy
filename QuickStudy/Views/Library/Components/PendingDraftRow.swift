//
//  PendingDraftRow.swift
//  QuickStudy
//

import SwiftUI

struct PendingDraftRow: View {
    let draft: DraftSet
    let onResume: () -> Void
    let onDiscard: () -> Void

    @State private var showDiscardAlert = false

    private static let ageFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                    .frame(width: 36, height: 36)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.md) {
                Button("Discard") { showDiscardAlert = true }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Button(action: onResume) {
                    Text("Resume")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.md)
                }
                .appProminentButtonStyle(tint: Theme.primary)
            }
        }
        .padding(Spacing.md)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .alert("Discard draft?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive, action: onDiscard)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The \(draft.cards.count) drafted \(noun) will be deleted. This used one of your free generations.")
        }
    }

    private var noun: String {
        draft.cards.count == 1 ? "card" : "cards"
    }

    private var subtitle: String {
        let age = Self.ageFormatter.localizedString(for: draft.createdAt, relativeTo: Date())
        return "\(draft.cards.count) \(noun) drafted · \(age)"
    }
}

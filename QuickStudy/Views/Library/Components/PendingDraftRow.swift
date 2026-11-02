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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var tileSize = 36.0

    private static let ageFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        let stacksVertically = dynamicTypeSize.isAccessibilitySize
        let headerLayout = stacksVertically
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        VStack(alignment: .leading, spacing: Spacing.md) {
            headerLayout {
                Image(systemName: "doc.badge.plus")
                    .font(.subheadline)
                    .foregroundStyle(Theme.primary)
                    .frame(width: tileSize, height: tileSize)
                    .background(Theme.primary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(draft.title)
                        .font(.headline)
                        .lineLimit(stacksVertically ? nil : 1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)

                if !stacksVertically { Spacer(minLength: 0) }
            }

            let actionLayout = stacksVertically
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
                : AnyLayout(HStackLayout(spacing: Spacing.md))

            actionLayout {
                Button { showDiscardAlert = true } label: {
                    Text("Discard")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .contentShape(.rect)
                }
                .accessibilityLabel("Discard draft")
                .accessibilityInputLabels(["Discard", "Discard draft"])

                if !stacksVertically {
                    Spacer(minLength: 0)
                }

                Button(action: onResume) {
                    Text("Resume")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, Spacing.md)
                }
                .appProminentButtonStyle(tint: Theme.primaryFill)
                .accessibilityLabel("Resume draft")
                .accessibilityInputLabels(["Resume", "Resume draft"])
            }
        }
        .padding(Spacing.md)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .appTransition(.move(edge: .top).combined(with: .opacity))
        .alert("Discard draft?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive, action: onDiscard)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(draft.discardWarning)
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

//
//  DraftCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct DraftCardRow: View {
    @Binding var card: StudyCard
    var onRemove: () -> Void

    @State private var isEditing = false
    @AccessibilityFocusState private var questionFieldFocused: Bool
    @AccessibilityFocusState private var summaryFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                TextField("Question", text: $card.question, axis: .vertical)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .accessibilityFocused($questionFieldFocused)
                TextField("Answer", text: $card.answer, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    isEditing = true
                    questionFieldFocused = true
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(card.question)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(card.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityFocused($summaryFocused)
                .accessibilityLabel("\(card.question). \(card.answer)")
                .accessibilityHint("Double tap to edit")
            }

            HStack {
                if let source = card.source {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "link")
                        Text(source.shortLabel)
                    }
                    .font(.caption2)
                    .foregroundStyle(Color.appPrimary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, 3)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(sourceAccessibilityLabel(source))
                }
                Spacer()
                if isEditing {
                    Button("Done") {
                        isEditing = false
                        summaryFocused = true
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                } else {
                    Image(systemName: "pencil")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityAction(named: "Edit") {
            isEditing = true
            questionFieldFocused = true
        }
        .accessibilityAction(named: "Remove", onRemove)
    }

    private func sourceAccessibilityLabel(_ source: CardSource) -> String {
        var parts: [String] = []
        if let page = source.page { parts.append("page \(page)") }
        if let paragraph = source.paragraph { parts.append("paragraph \(paragraph)") }
        guard !parts.isEmpty else { return "Source: \(source.documentTitle)" }
        return "Source: " + parts.joined(separator: ", ")
    }
}

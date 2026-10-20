//
//  DraftCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct DraftCardRow: View {
    enum Field {
        case question
        case answer
    }

    @Binding var card: StudyCard
    var onRemove: () -> Void

    @State private var isEditing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var summaryFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TextField("Question", text: $card.question, axis: .vertical)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .focused($focusedField, equals: .question)
                        .padding(Spacing.sm)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(Color.appPrimary.opacity(focusedField == .question ? 0.6 : 0.25))
                        }
                    TextField("Answer", text: $card.answer, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .focused($focusedField, equals: .answer)
                        .padding(Spacing.sm)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(Color.appPrimary.opacity(focusedField == .answer ? 0.6 : 0.25))
                        }
                }
                // The fields only exist once editing starts, so focus is requested on
                // appearance; setting it in the tap handler targets a field not yet built.
                .onAppear { focusedField = .question }
                .appTransition(.opacity)
            } else {
                Button {
                    withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                        isEditing = true
                    }
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
                .appTransition(.opacity)
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
                        focusedField = nil
                        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                            isEditing = false
                        }
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
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                isEditing = true
            }
        }
        .accessibilityAction(named: "Remove", onRemove)
        .onChange(of: isEditing) { _, editing in
            if !editing { summaryFocused = true }
        }
        // Tapping another card moves focus there; this one closes rather than staying
        // half-open with no caret.
        .onChange(of: focusedField) { _, field in
            guard field == nil, isEditing else { return }
            withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                isEditing = false
            }
        }
    }

    private func sourceAccessibilityLabel(_ source: CardSource) -> String {
        var parts: [String] = []
        if let page = source.page { parts.append("page \(page)") }
        if let paragraph = source.paragraph { parts.append("paragraph \(paragraph)") }
        guard !parts.isEmpty else { return "Source: \(source.documentTitle)" }
        return "Source: " + parts.joined(separator: ", ")
    }
}

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
    @AccessibilityFocusState.Binding var accessibilityFocusedCardID: UUID?
    var onRemove: () -> Void

    @State private var isEditing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    TextField("Question", text: $card.question, axis: .vertical)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .accessibilityLabel("Question")
                        .focused($focusedField, equals: .question)
                        .padding(Spacing.sm)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(focusedField == .question ? Color.appPrimary : Theme.hairline,
                                              lineWidth: focusedField == .question ? 2 : 1)
                        }
                    TextField("Answer", text: $card.answer, axis: .vertical)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Answer")
                        .focused($focusedField, equals: .answer)
                        .padding(Spacing.sm)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.sm)
                                .strokeBorder(focusedField == .answer ? Color.appPrimary : Theme.hairline,
                                              lineWidth: focusedField == .answer ? 2 : 1)
                        }
                }
                // The fields only exist once editing starts, so focus is requested on
                // appearance; setting it in the tap handler targets a field not yet built.
                .onAppear { focusedField = .question }
                .appTransition(.opacity)

                HStack {
                    if let source = card.source {
                        DraftSourcePill(source: source)
                    }
                    Spacer()
                    Button {
                        focusedField = nil
                        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
                            isEditing = false
                        }
                    } label: {
                        Text("Done")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
                }
            } else {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Button(action: startEditing) {
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

                    HStack {
                        if let source = card.source {
                            DraftSourcePill(source: source)
                        }
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spokenSummary)
                .accessibilityValue(spokenSource)
                .accessibilityHint("Double tap to edit")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(.default, startEditing)
                .accessibilityAction(named: "Edit", startEditing)
                .accessibilityAction(named: "Remove", onRemove)
                .accessibilityFocused($accessibilityFocusedCardID, equals: card.id)
                .appTransition(.opacity)
            }
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .onChange(of: isEditing) { _, editing in
            if !editing { accessibilityFocusedCardID = card.id }
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

    private var spokenSummary: String {
        "\(card.question). \(card.answer)"
    }

    private var spokenSource: String {
        guard let source = card.source else { return "" }
        return DraftSourcePill.spokenLabel(for: source)
    }

    private func startEditing() {
        withAnimation(reduceMotion ? Motion.crossfade : Motion.snappy) {
            isEditing = true
        }
    }
}

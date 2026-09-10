//
//  DraftCardRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct DraftCardRow: View {
    @Binding var card: StudyCard
    @State private var isEditing = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if isEditing {
                TextField("Question", text: $card.question, axis: .vertical)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Answer", text: $card.answer, axis: .vertical)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(card.question)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(card.answer)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                }
                Spacer()
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .contentShape(Rectangle())
        .onTapGesture { isEditing.toggle() }
    }
}

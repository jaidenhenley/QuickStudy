//
//  CardRowView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/6/26.
//

import SwiftUI

struct CardRowView: View {
    @Binding var card: StudyCard
    let deleteCard: () -> Void

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    if isEditing {
                        TextField("Question", text: $card.question, axis: .vertical)
                            .font(.headline)
                            .textFieldStyle(.roundedBorder)
                        TextEditor(text: $card.answer)
                            .font(.subheadline)
                            .frame(minHeight: 90)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                    } else {
                        Text(card.question)
                            .font(.headline)
                        Text(card.answer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("Approve")
                    Toggle("", isOn: $card.approved)
                        .labelsHidden()
                        .accessibilityLabel("Approve")
                }
                .toggleStyle(.switch)
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                }
                .accessibilityLabel(isEditing ? "Done editing" : "Edit card")
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete card")
            }

        }
        .padding(12)
        .appGlassCard(cornerRadius: 16)
        .alert("Delete Card", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteCard()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this card? This cannot be undone.")
        }
    }
}

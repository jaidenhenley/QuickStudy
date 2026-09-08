//
//  NewSetSheet.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct NewSetSheet: View {
    let coordinator: ImportCoordinator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Set")
                .font(.title2)
                .fontWeight(.bold)

            Text("Snap a page, drop in a PDF, or paste your notes — we'll draft flashcards in seconds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SourceOptionButton(title: "Scan", systemImage: "camera", isProminent: true) {
                    coordinator.pendingSource = .scan
                    dismiss()
                }
                SourceOptionButton(title: "PDF", systemImage: "doc.text") {
                    coordinator.pendingSource = .pdf
                    dismiss()
                }
                SourceOptionButton(title: "Paste", systemImage: "text.alignleft") {
                    coordinator.pendingSource = .paste
                    dismiss()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.height(240)])
        .presentationDragIndicator(.visible)
    }
}

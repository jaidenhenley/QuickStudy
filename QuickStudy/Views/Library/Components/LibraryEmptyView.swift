//
//  LibraryEmptyView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct LibraryEmptyView: View {
    let coordinator: ImportCoordinator

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .foregroundStyle(Color.appPrimary.opacity(0.35))
                    .frame(width: 132, height: 96)
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundStyle(Color.appPrimary)
            }
            .padding(.bottom, 8)

            Text("Build your first set")
                .font(.title2)
                .fontWeight(.bold)

            Text("Snap a page, drop in a PDF, or paste your notes — we'll draft flashcards in seconds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                SourceOptionButton(title: "PDF", systemImage: "doc.text") {
                    coordinator.showFileImporter = true
                }
                SourceOptionButton(title: "Scan", systemImage: "camera", isProminent: true) {
                    coordinator.startScan()
                }
                SourceOptionButton(title: "Paste", systemImage: "text.alignleft") {
                    coordinator.showPasteSheet = true
                }
            }
            .padding(.top, 8)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.appAIAccent)
                Text("Tip: works best with **1–3 pages of notes** at a time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.top, 8)
        }
        .padding(.horizontal, 20)
    }
}

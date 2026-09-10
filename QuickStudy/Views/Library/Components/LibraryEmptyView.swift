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
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .frame(width: 116, height: 92)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -26, y: -6)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.35))
                    .frame(width: 116, height: 92)
                    .rotationEffect(.degrees(7))
                    .offset(x: 26, y: -6)

                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .frame(width: 118, height: 96)
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title)
                            .foregroundStyle(Color.appPrimary)
                    }
            }
            .padding(.bottom, 6)

            Text("Build your first set")
                .font(.title2)
                .fontWeight(.bold)

            Text("Snap a page, drop in a PDF, or paste your notes — we'll draft flashcards in seconds.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                SourceOptionButton(title: "PDF", subtitle: "Files", systemImage: "doc.text") {
                    coordinator.showFileImporter = true
                }
                SourceOptionButton(title: "Scan", subtitle: "Camera", systemImage: "camera") {
                    coordinator.startScan()
                }
                SourceOptionButton(title: "Text", subtitle: "Paste", systemImage: "text.alignleft") {
                    coordinator.showPasteSheet = true
                }
            }
            .padding(.top, 4)

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: 28, height: 28)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Text("Tip: works best with **1–3 pages of notes** at a time.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .appGlassCard(cornerRadius: AppRadius.md)
        }
    }
}

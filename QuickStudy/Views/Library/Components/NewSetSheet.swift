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
        VStack(alignment: .leading, spacing: Spacing.base) {
            HStack {
                Text("New set")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") { dismiss() }
            }

            Text("Capture a page — cards draft automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                coordinator.pendingSource = .scan
                dismiss()
            } label: {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "camera")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan with camera")
                            .font(.headline)
                        Text("Fastest · recommended")
                            .font(.caption)
                            .opacity(0.8)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.footnote)
                }
                .foregroundStyle(.white)
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary)
            }
            .buttonStyle(.plain)

            HStack(spacing: Spacing.md) {
                SourceOptionButton(title: "Photo", subtitle: "Library", systemImage: "photo") {
                    coordinator.pendingSource = .photo
                    dismiss()
                }
                SourceOptionButton(title: "PDF", subtitle: "Files", systemImage: "doc.text") {
                    coordinator.pendingSource = .pdf
                    dismiss()
                }
                SourceOptionButton(title: "Text", subtitle: "Paste", systemImage: "text.alignleft") {
                    coordinator.pendingSource = .paste
                    dismiss()
                }
            }

            Spacer(minLength: 0)
        }
        .padding(Spacing.lg)
        .presentationDetents([.height(320)])
        .presentationDragIndicator(.visible)
    }
}

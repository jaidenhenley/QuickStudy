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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ScaledMetric(relativeTo: .title3) private var iconTileSize: CGFloat = 44

    var body: some View {
        let optionLayout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.md))
            : AnyLayout(HStackLayout(spacing: Spacing.md))

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.base) {
                HStack {
                    Text("New set")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .frame(minHeight: 44)
                }

                Text("Capture a page and cards draft automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    coordinator.pendingSource = .scan
                    dismiss()
                } label: {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: "camera")
                            .font(.title3)
                            .frame(width: iconTileSize, height: iconTileSize)
                            .background(Theme.onPrimary.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan with camera")
                                .font(.headline)
                            Text("Fastest · recommended")
                                .font(.caption)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(Theme.onPrimary)
                    .padding(Spacing.base)
                    .background {
                        if reduceTransparency {
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .fill(Theme.primaryFill)
                        }
                    }
                    .appGlassCard(cornerRadius: AppRadius.lg, tint: Theme.primaryFill)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scan with camera, Fastest, recommended")

                optionLayout {
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
            }
            .padding(Spacing.lg)
        }
        .scrollBounceBehavior(.basedOnSize)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(320)])
        .presentationDragIndicator(.visible)
    }
}

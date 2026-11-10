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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.base) {
                    if coordinator.isScannerSupported {
                        Button {
                            choose(.scan)
                        } label: {
                            HStack(spacing: Spacing.md) {
                                SourceTile(systemImage: "camera.viewfinder", tint: Theme.onPrimary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Scan Document")
                                        .font(.headline)
                                    Text("Fastest · recommended")
                                        .font(.footnote)
                                }
                                .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(Theme.onPrimary)
                            .padding(Spacing.base)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .background {
                                if reduceTransparency {
                                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                        .fill(Theme.primaryFill)
                                }
                            }
                            .appGlassCard(cornerRadius: AppRadius.lg, tint: Theme.primaryFill)
                            .contentShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Scan Document, Fastest · recommended")
                        .accessibilityAddTraits(.isButton)
                    }

                    VStack(spacing: 0) {
                        SourceRow(title: "Choose Photo", subtitle: "From your photo library", systemImage: "photo.on.rectangle") {
                            choose(.photo)
                        }
                        Divider().padding(.leading, Spacing.base)
                        SourceRow(title: "Choose PDF", subtitle: "From Files", systemImage: "doc.fill") {
                            choose(.pdf)
                        }
                        Divider().padding(.leading, Spacing.base)
                        SourceRow(title: "Paste Text", subtitle: "From Notes, Safari or any app", systemImage: "doc.text") {
                            choose(.paste)
                        }
                    }
                    .appGlassCard(cornerRadius: AppRadius.lg)

                    Text("Works best with 1 to 10 pages of notes.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Spacing.base)
                }
                .padding(.horizontal, Spacing.base)
                .padding(.bottom, Spacing.base)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(BackgroundView())
            .navigationTitle("New Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium])
        .presentationDragIndicator(.visible)
    }

    private func choose(_ source: ImportCoordinator.ImportSource) {
        coordinator.pendingSource = source
        dismiss()
    }
}

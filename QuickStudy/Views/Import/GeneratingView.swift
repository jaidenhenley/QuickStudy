//
//  GeneratingView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct GeneratingView: View {
    let stage: ImportCoordinator.Stage
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Text("Scanning…")
                    .font(.headline)
                Spacer()
                Text("Cancel").opacity(0)
            }

            Spacer()

            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Theme.surface)
                .frame(width: 200, height: 260)
                .overlay {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        ForEach(0..<9, id: \.self) { row in
                            Capsule()
                                .fill(Color.secondary.opacity(0.25))
                                .frame(height: 8)
                                .padding(.trailing, row % 3 == 2 ? 48 : 0)
                        }
                    }
                    .padding(Spacing.lg)
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "sparkles")
                    Text("DRAFTING CARDS")
                        .tracking(1)
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.appPrimary)

                Text(headline)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("This usually takes 4–6 seconds.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ProgressView(value: fraction)
                    .tint(Color.appPrimary)
                    .padding(.top, Spacing.sm)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
    }

    private var headline: String {
        switch stage {
        case .idle, .drafting:
            return "Drafting cards"
        case let .reading(page, total):
            return "Reading page \(max(1, page)) of \(total)"
        }
    }

    private var fraction: Double {
        switch stage {
        case .idle:
            return 0
        case let .reading(page, total):
            return total == 0 ? 0 : Double(page) / Double(total + 1)
        case .drafting:
            return 0.9
        }
    }
}

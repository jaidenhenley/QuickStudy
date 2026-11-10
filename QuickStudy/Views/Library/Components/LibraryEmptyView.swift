//
//  LibraryEmptyView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct LibraryEmptyView: View {
    @ScaledMetric(relativeTo: .caption) private var tipTileSize = 28.0

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Theme.hairline)
                    .frame(width: 116, height: 92)
                    .rotationEffect(.degrees(-7))
                    .offset(x: -26, y: -6)

                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .foregroundStyle(Theme.hairline)
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
            .accessibilityHidden(true)

            Text("Build your first set")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Text("Tap + to scan, import or paste your first notes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color.appPrimary)
                    .frame(width: tipTileSize, height: tipTileSize)
                    .background(Color.appPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
                Text("Works best with **1 to 10 pages of notes**.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .appGlassCard(cornerRadius: AppRadius.md)
            .accessibilityElement(children: .combine)
        }
    }
}

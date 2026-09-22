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

    @Environment(StudyViewModel.self) private var studyViewModel

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

            // Redraws on a timer so elapsed time and the bar stay live for the whole run.
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles")
                        Text("DRAFTING CARDS")
                            .tracking(1)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPrimary)

                    Text(headline(at: context.date))
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(detail(at: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    ProgressView(value: fraction(at: context.date))
                        .tint(Color.appPrimary)
                        .padding(.top, Spacing.sm)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
    }

    private func headline(at now: Date) -> String {
        let progress = studyViewModel.generationProgress
        switch stage {
        case let .reading(page, total):
            return "Reading page \(max(1, page)) of \(total)"
        case .idle, .drafting:
            guard progress.isChunked else { return "Drafting cards" }
            return "Drafting cards · \(min(progress.completedUnits + 1, progress.totalUnits)) of \(progress.totalUnits)"
        }
    }

    private func detail(at now: Date) -> String {
        let progress = studyViewModel.generationProgress
        guard case .reading = stage else {
            if progress.isOverrunning(now: now) { return "Still working…" }
            if progress.isChunked { return "Working through your notes in sections." }
            return progress.readsWholeDocument
                ? "Reading the whole document."
                : "Drafting on this iPhone."
        }
        return "Reading your pages before drafting."
    }

    private func fraction(at now: Date) -> Double {
        switch stage {
        case .idle:
            return 0
        case let .reading(page, total):
            return total == 0 ? 0 : Double(page) / Double(total + 1)
        case .drafting:
            return studyViewModel.generationProgress.fraction(now: now)
        }
    }
}

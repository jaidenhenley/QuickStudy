//
//  GeneratingView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct GeneratingView: View {
    let stage: ImportCoordinator.Stage
    let source: ImportCoordinator.ImportSource?
    let onCancel: () -> Void

    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Text(headerTitle)
                    .font(.headline)
                Spacer()
                Text("Cancel").opacity(0)
            }

            Spacer()

            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(Theme.surface)
                .frame(width: 200, height: 260)
                .overlay {
                    PhaseAnimator(reduceMotion ? [1] : [0.35, 0.7]) { phase in
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            ForEach(0..<9, id: \.self) { row in
                                Capsule()
                                    .fill(Color.secondary.opacity(0.25))
                                    .frame(height: 8)
                                    .padding(.trailing, row % 3 == 2 ? 48 : 0)
                            }
                        }
                        .padding(Spacing.lg)
                        .opacity(phase)
                    } animation: { _ in Motion.shimmer }
                }
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)

            // Redraws on a timer so elapsed time and the bar stay live for the whole run.
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                let currentHeadline = headline(at: context.date)
                let currentFraction = fraction(at: context.date)
                let isReadingPhase: Bool = if case .reading = stage { true } else { false }

                VStack(spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles")
                        Text("DRAFTING CARDS")
                            .tracking(1)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPrimary)

                    Text(currentHeadline)
                        .font(.title2)
                        .fontWeight(.bold)
                        .contentTransition(.numericText())
                        .appAnimation(Motion.snappy, value: currentHeadline)

                    Text(detail(at: context.date))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    ProgressView(value: currentFraction)
                        .tint(Color.appPrimary)
                        .padding(.top, Spacing.sm)
                        .appAnimation(Motion.progressTick, value: currentFraction)
                }
                .id(isReadingPhase)
                .appTransition(.opacity)
                .appAnimation(Motion.standard, value: isReadingPhase)
                .sensoryFeedback(.levelChange, trigger: isReadingPhase)
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
    }

    private var headerTitle: String {
        switch source {
        case .scan: return "Scanning…"
        case .photo, .pdf: return "Importing…"
        case .paste, .none: return "Drafting…"
        }
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

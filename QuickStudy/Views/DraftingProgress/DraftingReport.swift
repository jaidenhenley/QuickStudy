//
//  DraftingReport.swift
//  QuickStudy
//

import Foundation

struct DraftingReport: Equatable {
    enum Phase: Equatable {
        case drafting
        case ready
    }

    enum StepState: Equatable {
        case done
        case active
        case pending
    }

    struct Step: Equatable, Identifiable {
        let title: String
        let detail: String?
        let state: StepState

        var id: String { title }
    }

    let phase: Phase
    let documentTitle: String
    let headline: String
    let detail: String?
    let fraction: Double?
    let steps: [Step]
    let engine: GenerationProvenance.Engine?
    let sourceSummary: String?

    /// A run that finished keeps its report while its draft waits for review, so an open
    /// sheet can show the outcome instead of vanishing.
    @MainActor
    static func make(
        run: ImportCoordinator.DraftingRun?,
        stage: ImportCoordinator.Stage,
        status: ImportCoordinator.DraftingStatus?,
        progress: GenerationProgress,
        draft: DraftSet?,
        now: Date = .now
    ) -> DraftingReport? {
        guard let run else { return nil }
        if stage != .idle, let status {
            return drafting(run: run, stage: stage, status: status, progress: progress, now: now)
        }
        if run.finishedAt != nil, let draft {
            return ready(run: run, draft: draft)
        }
        return nil
    }

    @MainActor
    private static func drafting(
        run: ImportCoordinator.DraftingRun,
        stage: ImportCoordinator.Stage,
        status: ImportCoordinator.DraftingStatus,
        progress: GenerationProgress,
        now: Date
    ) -> DraftingReport {
        var steps: [Step] = []
        if run.readingStartedAt != nil {
            if case let .reading(page, total) = stage {
                let pages = max(total, 1)
                steps.append(Step(title: String(localized: "Read pages"), detail: String(localized: "Page \(min(page + 1, pages)) of \(pages)"), state: .active))
            } else {
                steps.append(readStepDone(run: run))
            }
        }
        if stage == .drafting {
            steps.append(Step(title: String(localized: "Draft cards"), detail: draftingDetail(progress: progress, now: now), state: .active))
        } else {
            steps.append(Step(title: String(localized: "Draft cards"), detail: nil, state: .pending))
        }
        steps.append(Step(title: String(localized: "Ready to review"), detail: nil, state: .pending))

        let isRunning = stage == .drafting && progress.startedAt != nil
        return DraftingReport(
            phase: .drafting,
            documentTitle: run.title,
            headline: status.detail,
            detail: nil,
            fraction: status.fraction,
            steps: steps,
            engine: isRunning ? progress.engine : nil,
            sourceSummary: sourceSummary(for: run)
        )
    }

    private static func ready(run: ImportCoordinator.DraftingRun, draft: DraftSet) -> DraftingReport {
        var steps: [Step] = []
        if run.readingStartedAt != nil {
            steps.append(readStepDone(run: run))
        }
        let cards = String(localized: "\(draft.cards.count) cards")
        let drafted = [cards, duration(from: run.draftingStartedAt, to: run.finishedAt)].compactMap(\.self)
        steps.append(Step(title: String(localized: "Draft cards"), detail: drafted.joined(separator: " · "), state: .done))
        steps.append(Step(title: String(localized: "Ready to review"), detail: nil, state: .done))

        return DraftingReport(
            phase: .ready,
            documentTitle: run.title,
            headline: LibraryViewModel.readyTitle(for: draft),
            detail: LibraryViewModel.readyDetail(for: draft),
            fraction: 1,
            steps: steps,
            engine: draft.provenance?.engine,
            sourceSummary: sourceSummary(for: run)
        )
    }

    private static func readStepDone(run: ImportCoordinator.DraftingRun) -> Step {
        let parts = [
            run.pageCount.map { String(localized: "\($0) pages") },
            duration(from: run.readingStartedAt, to: run.readingFinishedAt),
        ].compactMap(\.self)
        return Step(title: String(localized: "Read pages"), detail: parts.isEmpty ? nil : parts.joined(separator: " · "), state: .done)
    }

    @MainActor
    private static func draftingDetail(progress: GenerationProgress, now: Date) -> String {
        guard progress.startedAt != nil else { return String(localized: "Getting started") }
        if progress.isChunked {
            return String(localized: "Part \(min(progress.completedUnits + 1, progress.totalUnits)) of \(progress.totalUnits)")
        }
        if let timeLeft = ImportCoordinator.timeLeft(in: progress, now: now, capitalized: true) {
            return timeLeft
        }
        let elapsed = duration(from: progress.startedAt, to: now) ?? Duration.seconds(1).formatted(.units(allowed: [.minutes, .seconds], width: .narrow))
        return progress.isOverrunning(now: now)
            ? String(localized: "Taking longer than usual · \(elapsed) so far")
            : String(localized: "\(elapsed) so far")
    }

    private static func sourceSummary(for run: ImportCoordinator.DraftingRun) -> String? {
        let pages = run.readingStartedAt == nil ? nil : run.pageCount.map { String(localized: "\($0) pages") }
        let words = run.wordCount.map { String(localized: "\($0) words") }
        let parts = [pages, words].compactMap(\.self)
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private static func duration(from start: Date?, to end: Date?) -> String? {
        guard let start, let end else { return nil }
        let seconds = max(1, Int(end.timeIntervalSince(start).rounded()))
        return Duration.seconds(seconds).formatted(.units(allowed: [.minutes, .seconds], width: .narrow))
    }
}

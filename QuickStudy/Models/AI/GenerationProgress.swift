//
//  GenerationProgress.swift
//  QuickStudy
//

import Foundation

/// Live state behind the drafting screen. On-device generation reports real chunk
/// counts; a hosted call is one network round trip with nothing to report, so it
/// publishes an expected duration and the screen tracks elapsed time against it.
@MainActor
@Observable
final class GenerationProgress {
    private(set) var completedUnits = 0
    private(set) var totalUnits = 0
    private(set) var startedAt: Date?
    private(set) var unitStartedAt: Date?
    private(set) var expectedSeconds: Double = 6
    private(set) var readsWholeDocument = false

    var isChunked: Bool { totalUnits > 1 }

    func begin(expectedSeconds: Double, readsWholeDocument: Bool) {
        completedUnits = 0
        totalUnits = 0
        self.expectedSeconds = expectedSeconds
        self.readsWholeDocument = readsWholeDocument
        startedAt = Date()
        unitStartedAt = startedAt
    }

    func setTotalUnits(_ count: Int) {
        totalUnits = max(0, count)
    }

    func advance() {
        completedUnits += 1
        unitStartedAt = Date()
    }

    func end() {
        startedAt = nil
    }

    func elapsed(now: Date = Date()) -> Double {
        guard let startedAt else { return 0 }
        return max(0, now.timeIntervalSince(startedAt))
    }

    /// `expectedSeconds` describes one unit of work, so pacing and overrun are measured
    /// against the current chunk rather than the whole run.
    private func elapsedInUnit(now: Date) -> Double {
        guard let unitStartedAt else { return 0 }
        return max(0, now.timeIntervalSince(unitStartedAt))
    }

    /// Never reaches 1 on its own — the screen is dismissed by completion, so a full bar
    /// that keeps waiting reads as a hang.
    func fraction(now: Date = Date()) -> Double {
        if isChunked {
            let done = Double(completedUnits) / Double(totalUnits)
            let withinUnit = min(elapsedInUnit(now: now) / max(expectedSeconds, 1), 1) / Double(totalUnits)
            return min(done + withinUnit, 0.97)
        }
        return min(elapsedInUnit(now: now) / max(expectedSeconds, 1), 0.97)
    }

    func isOverrunning(now: Date = Date()) -> Bool {
        elapsedInUnit(now: now) > expectedSeconds * 2
    }
}

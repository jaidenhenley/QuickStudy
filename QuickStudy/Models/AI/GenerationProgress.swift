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
    private(set) var engine: GenerationProvenance.Engine = .onDevice

    var isChunked: Bool { totalUnits > 1 }

    func begin(expectedSeconds: Double, engine: GenerationProvenance.Engine) {
        completedUnits = 0
        totalUnits = 0
        self.expectedSeconds = expectedSeconds
        self.engine = engine
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
        let withinUnit = Self.eased(elapsed: elapsedInUnit(now: now), expected: expectedSeconds)
        guard isChunked else { return withinUnit }
        return min((Double(completedUnits) + withinUnit) / Double(totalUnits), 0.97)
    }

    /// Halfway at the expected time and still creeping long after it. A linear ramp hit
    /// its cap at `expectedSeconds` and then sat still for however long the model took.
    private static func eased(elapsed: Double, expected: Double) -> Double {
        min(elapsed / (elapsed + max(expected, 1)), 0.97)
    }

    func isOverrunning(now: Date = Date()) -> Bool {
        elapsedInUnit(now: now) > expectedSeconds * 2
    }
}

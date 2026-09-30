//
//  ReleaseTracker.swift
//  QuickStudy
//

import Foundation

struct ReleaseTracker {
    enum LaunchSheet: Equatable {
        case onboarding
        case whatsNew(ReleaseNote)
    }

    private static let lastSeenKey = "qs_lastSeenRelease"
    /// Only 1.0 wrote this, so its presence marks an upgrader even after they delete every set.
    private static let legacyOnboardingKey = "didShowOnboarding"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var lastSeenRelease: Int { defaults.integer(forKey: Self.lastSeenKey) }

    func noteToShow(hasUserSets: Bool, current: ReleaseNote = ReleaseNotes.current) -> ReleaseNote? {
        guard lastSeenRelease == 0 else {
            return lastSeenRelease < current.release ? current : nil
        }
        let isUpgrader = hasUserSets || defaults.object(forKey: Self.legacyOnboardingKey) != nil
        return isUpgrader ? current : nil
    }

    func launchSheet(
        hasUserSets: Bool,
        hasCompletedOnboarding: Bool,
        current: ReleaseNote = ReleaseNotes.current
    ) -> LaunchSheet? {
        let note = noteToShow(hasUserSets: hasUserSets, current: current)
        // A recorded release means this install began after 1.0, so an unfinished
        // onboarding resumes instead of being skipped for release notes.
        if !hasCompletedOnboarding && (note == nil || lastSeenRelease > 0) {
            return .onboarding
        }
        return note.map(LaunchSheet.whatsNew)
    }

    func markSeen(_ note: ReleaseNote = ReleaseNotes.current) {
        defaults.set(max(lastSeenRelease, note.release), forKey: Self.lastSeenKey)
    }
}

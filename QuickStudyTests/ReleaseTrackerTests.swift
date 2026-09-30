//
//  ReleaseTrackerTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct ReleaseTrackerTests {
    private func makeDefaults(_ name: String = #function) -> UserDefaults {
        let suiteName = "ReleaseTrackerTests.\(name).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func note(release: Int) -> ReleaseNote {
        ReleaseNote(
            release: release,
            version: "\(release).0",
            headline: "Headline",
            features: [],
            proFeature: nil,
            cloudNotice: nil
        )
    }

    @Test func freshInstallSeesNothing() {
        let tracker = ReleaseTracker(defaults: makeDefaults())

        #expect(tracker.noteToShow(hasUserSets: false, current: note(release: 2)) == nil)
    }

    @Test func upgraderWithSetsSeesCurrent() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        let current = note(release: 2)

        #expect(tracker.noteToShow(hasUserSets: true, current: current) == current)
    }

    @Test func upgraderWithOnlyLegacyFlagSeesCurrent() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "didShowOnboarding")
        let tracker = ReleaseTracker(defaults: defaults)
        let current = note(release: 2)

        #expect(tracker.noteToShow(hasUserSets: false, current: current) == current)
    }

    @Test func seenReleaseIsNotShownAgain() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        let current = note(release: 2)

        tracker.markSeen(current)

        #expect(tracker.noteToShow(hasUserSets: true, current: current) == nil)
    }

    @Test func installMarkedSeenStaysHiddenOnceSetsExist() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        let current = note(release: 2)

        tracker.markSeen(current)

        #expect(tracker.noteToShow(hasUserSets: true, current: current) == nil)
        #expect(tracker.lastSeenRelease == 2)
    }

    @Test func newerReleaseShowsAfterPreviousWasSeen() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        tracker.markSeen(note(release: 2))
        let next = note(release: 3)

        #expect(tracker.noteToShow(hasUserSets: false, current: next) == next)
    }

    @Test func freshInstallLaunchesOnboarding() {
        let tracker = ReleaseTracker(defaults: makeDefaults())

        let sheet = tracker.launchSheet(hasUserSets: false, hasCompletedOnboarding: false, current: note(release: 2))

        #expect(sheet == .onboarding)
    }

    @Test func upgraderLaunchesWhatsNewInsteadOfOnboarding() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        let current = note(release: 2)

        let sheet = tracker.launchSheet(hasUserSets: true, hasCompletedOnboarding: false, current: current)

        #expect(sheet == .whatsNew(current))
    }

    @Test func unfinishedOnboardingResumesWhenNewReleaseShips() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        tracker.markSeen(note(release: 2))

        let sheet = tracker.launchSheet(hasUserSets: false, hasCompletedOnboarding: false, current: note(release: 3))

        #expect(sheet == .onboarding)
    }

    @Test func onboardedUserSeesNextRelease() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        tracker.markSeen(note(release: 2))
        let next = note(release: 3)

        let sheet = tracker.launchSheet(hasUserSets: true, hasCompletedOnboarding: true, current: next)

        #expect(sheet == .whatsNew(next))
    }

    @Test func onboardedUserOnSeenReleaseGetsNoSheet() {
        let tracker = ReleaseTracker(defaults: makeDefaults())
        let current = note(release: 2)
        tracker.markSeen(current)

        #expect(tracker.launchSheet(hasUserSets: true, hasCompletedOnboarding: true, current: current) == nil)
    }

    @Test func markSeenNeverMovesBackwards() {
        let tracker = ReleaseTracker(defaults: makeDefaults())

        tracker.markSeen(note(release: 3))
        tracker.markSeen(note(release: 2))

        #expect(tracker.lastSeenRelease == 3)
    }
}

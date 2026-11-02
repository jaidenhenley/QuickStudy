import XCTest

final class SmokeTests: QSTestCase {
    private static let landmarks: [SeedState: [String]] = [
        .freshInstall: ["Get Started"],
        .onboardedEmpty: ["Build your first set"],
        .demoData: ["Start Session", "TODAY'S SESSION"],
        .midDraft: ["Today"],
        .userSet: ["Today"],
        .proActive: ["Build your first set"],
        .allowanceSpent: ["Build your first set"],
        .hostedConsentDeclined: ["Build your first set"],
        .freeHostedSpent: ["Build your first set"],
        .noAppleIntelligence: ["Build your first set"]
    ]

    /// File-backed states only show their landmark when Scripts/seed.sh ran first; run.sh
    /// reports the seeded state in QS_SEEDED_STATE.
    private static let seededLandmarks: [SeedState: [String]] = [
        .midDraft: ["6 cards drafted · not yet saved"]
    ]

    /// freshInstall wipes Documents, so it runs last and the seeded draft survives until midDraft is checked.
    private static let order = SeedState.allCases.filter { !$0.resetsInstall } + [.freshInstall]

    func testEverySeedStateLaunchesWithContent() {
        let only = ProcessInfo.processInfo.environment["QS_SMOKE_ONLY"].flatMap(SeedState.init(rawValue:))
        let seeded = ProcessInfo.processInfo.environment["QS_SEEDED_STATE"]
        continueAfterFailure = true

        for state in Self.order where only == nil || only == state {
            XCTContext.runActivity(named: "Seed state \(state.rawValue)") { _ in
                let app = launch(state)
                let report = app.assertNotBlank("smoke-\(state.rawValue)", in: self)
                app.screenshot(named: "smoke-\(state.rawValue)", in: self)
                app.dumpHierarchy(named: "smoke-\(state.rawValue)", in: self)

                var expected = Self.landmarks[state] ?? []
                if state.needsFileSeed, seeded == state.rawValue {
                    expected = Self.seededLandmarks[state] ?? expected
                }
                if let found = app.waitForAny(expected, timeout: QSApp.uiTimeout) {
                    add(XCTAttachment(string: "\(state.rawValue): found '\(found)'. \(report.summary)"))
                } else {
                    Evidence.screenshot("smoke-\(state.rawValue)-NO-LANDMARK", app: app, in: self)
                    XCTFail("\(state.rawValue): none of \(expected) on screen. \(report.summary)")
                }
                app.terminate()
                StoreKitTesting.stopSession()
            }
        }
    }
}

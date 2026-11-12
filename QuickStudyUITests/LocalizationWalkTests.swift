import XCTest

/// Walks the main screens in one language with the sample set, saving a screenshot of each
/// and listing any visible English that has a translation. Run once per language:
///
///     TEST_RUNNER_QS_LANGUAGE=ja TEST_RUNNER_QS_EVIDENCE_DIR=/tmp/qs-ja xcodebuild test \
///       -only-testing:QuickStudyUITests/LocalizationWalkTests ...
///
/// The App Store captures (01 to 07) follow the order of the store screenshot set.
final class LocalizationWalkTests: QSTestCase {
    private var untranslated: [String: Set<String>] = [:]
    private lazy var englishToCatch = Localized.englishValuesThatShouldBeTranslated()

    func testWalkMainScreensInLaunchLanguage() throws {
        // StoreKit draws the paywall in the store session's language, not the app's.
        let store = try StoreKitTesting.startSession()
        store.locale = Locale(identifier: Localized.localeIdentifier)
        launch(.freshInstall, .demoData, extraArguments: Localized.launchArguments)
        let language = Localized.language

        XCTAssertTrue(
            app.buttons[Localized.string("Start Session")].waitForExistence(timeout: QSApp.launchTimeout),
            "Today did not show Start Session in \(language)"
        )
        capture("02-today")

        app.tapTab(Localized.string("Library"))
        _ = app.buttons[Localized.string("New Set")].waitForExistence(timeout: QSApp.uiTimeout)
        capture("07-library")

        app.buttons[Localized.string("New Set")].firstMatch.tap()
        let newSet = app.navigationBars[Localized.string("New Set")]
        XCTAssertTrue(newSet.waitForExistence(timeout: QSApp.uiTimeout), "New Set did not open")
        Thread.sleep(forTimeInterval: 0.8)
        capture("01-newset")
        newSet.buttons[Localized.string("Close")].tap()
        XCTAssertTrue(newSet.waitUntilGone(), "New Set did not close")

        app.tapTab(Localized.string("Today"))
        app.buttons[Localized.string("Start Session")].tap()
        XCTAssertTrue(options.firstMatch.waitForExistence(timeout: QSApp.uiTimeout), "Quiz did not open")

        try choose(correct: true)
        capture("03-quiz-selected")
        submitAndReveal()
        capture("04-correct-why")
        next()

        try choose(correct: false)
        submitAndReveal()
        capture("05-wrong")
        next()

        let finished = [Localized.string("One more session"), Localized.string("Done")]
        for _ in 0..<12 where app.waitForAny(finished, timeout: 1) == nil {
            try choose(correct: true)
            submitAndReveal()
            next()
        }
        XCTAssertNotNil(app.waitForAny(finished), "Session Complete did not appear")
        Thread.sleep(forTimeInterval: 1.5)
        capture("06-complete")
        app.buttons[Localized.string("Done")].firstMatch.tap()

        app.tapTab(Localized.string("Today"))
        let streak = app.element(labelContaining: Localized.string("%lld day streak", count: 1))
        if streak.waitForExistence(timeout: QSApp.uiTimeout) {
            streak.tap()
            Thread.sleep(forTimeInterval: 1)
            capture("08-streak")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        } else {
            XCTFail("No streak link on Today after a session")
        }

        app.tapTab(Localized.string("Stats"))
        Thread.sleep(forTimeInterval: 1)
        capture("09-stats")

        app.tapTab(Localized.string("Today"))
        app.buttons[Localized.string("Settings")].tap()
        Thread.sleep(forTimeInterval: 1)
        capture("10-settings")
        let upgrade = app.buttons[Localized.string("Upgrade to QuickStudy Pro")]
        for _ in 0..<6 where !upgrade.isHittable { app.swipeUp() }
        if upgrade.isHittable {
            upgrade.tap()
            Thread.sleep(forTimeInterval: 4)
            capture("11-paywall")
        }

        reportUntranslated(language)
    }

    // MARK: - Quiz

    private var options: XCUIElementQuery {
        let pattern = NSRegularExpression.escapedPattern(for: Localized.string("Option %@, %@"))
            .replacingOccurrences(of: "%1\\$@", with: ".*")
            .replacingOccurrences(of: "%2\\$@", with: ".*")
            .replacingOccurrences(of: "%@", with: ".*")
        return app.buttons.matching(NSPredicate(format: "label MATCHES %@", "(?s)" + pattern))
    }

    /// The sample set's answers in the launch language, read from DemoData.swift.
    private lazy var answers: [String] = {
        let url = QSApp.repositoryRoot.appendingPathComponent("QuickStudy/Models/Demo/DemoData.swift")
        guard let source = try? String(contentsOf: url, encoding: .utf8),
              let regex = try? NSRegularExpression(pattern: #"answer: String\(localized: "([^"]+)""#)
        else { return [] }
        let range = NSRange(source.startIndex..., in: source)
        return regex.matches(in: source, range: range).compactMap { match in
            Range(match.range(at: 1), in: source).map { Localized.string(String(source[$0]), table: "SampleSet") }
        }
    }()

    private func choose(correct: Bool) throws {
        XCTAssertTrue(options.firstMatch.waitForExistence(timeout: QSApp.uiTimeout), "No answer options")
        let all = (0..<options.count).map { options.element(boundBy: $0) }
        // A wrong option can contain another card's answer, so the whole option text must match.
        let isAnswer: (XCUIElement) -> Bool = { option in self.answers.contains { option.label.hasSuffix(", " + $0) || option.label.hasSuffix("、" + $0) } }
        let pick = try XCTUnwrap(
            all.first { isAnswer($0) == correct },
            "No \(correct ? "correct" : "wrong") option among \(all.map(\.label))"
        )
        pick.tap()
        Thread.sleep(forTimeInterval: 0.4)
    }

    private func submitAndReveal() {
        app.buttons[Localized.string("Submit")].tap()
        XCTAssertTrue(
            app.buttons[Localized.string("Next question")].waitForExistence(timeout: QSApp.uiTimeout)
                || app.waitForAny([Localized.string("One more session"), Localized.string("Done")], timeout: 2) != nil,
            "Answer was not revealed"
        )
        Thread.sleep(forTimeInterval: 0.8)
    }

    private func next() {
        let next = app.buttons[Localized.string("Next question")]
        if next.exists { next.tap() }
        Thread.sleep(forTimeInterval: 1.2)
    }

    // MARK: - Evidence

    private func capture(_ name: String) {
        Evidence.screenshot("\(Localized.language)-\(name)", app: app, in: self)
        let labels = (app.staticTexts.allElementsBoundByIndex + app.buttons.allElementsBoundByIndex)
            .map(\.label)
            .filter { englishToCatch.contains($0) }
        if !labels.isEmpty { untranslated[name, default: []].formUnion(labels) }
    }

    private func reportUntranslated(_ language: String) {
        let lines = untranslated.sorted { $0.key < $1.key }
            .map { "\($0.key): \($0.value.sorted().joined(separator: " | "))" }
        let text = lines.isEmpty ? "No untranslated English found." : lines.joined(separator: "\n")
        let attachment = XCTAttachment(string: text)
        attachment.name = "\(language)-untranslated"
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = Evidence.directory.appendingPathComponent("\(language)-untranslated.txt")
        XCTAssertNoThrow(try text.write(to: url, atomically: true, encoding: .utf8))
    }
}

import XCTest

/// Helpers for sections D (Quiz) and E (Library, settings, paywall) of audit/e2e-test-script.md.
extension QSTestCase {
    var optionButtons: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Option '"))
    }

    var questionCounter: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Session, question'")).firstMatch
    }

    var nextButton: XCUIElement { app.buttons["Next question"] }

    var submitButton: XCUIElement { app.buttons["Submit"] }

    var backButton: XCUIElement { app.buttons["BackButton"] }

    /// "Session, question 3 of 5" -> (3, 5)
    func sessionPosition() -> (index: Int, total: Int)? {
        guard questionCounter.exists else { return nil }
        let numbers = questionCounter.label.split(whereSeparator: { !$0.isNumber }).compactMap { Int($0) }
        guard numbers.count >= 2 else { return nil }
        return (numbers[0], numbers[1])
    }

    /// "5 cards, 2 minutes" on Today's session card.
    func todayCardCount() -> Int? {
        let card = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES '^[0-9]+ cards?, [0-9]+ minutes?$'")).firstMatch
        guard card.waitForExistence(timeout: 4) else { return nil }
        return Int(card.label.split(separator: " ").first ?? "")
    }

    func goToToday() {
        app.tapTab("Today")
        _ = app.staticTexts["Today"].waitForExistence(timeout: 4)
    }

    func startSessionFromToday(_ id: String) {
        XCTAssertTrue(app.buttons["Start Session"].waitForExistence(timeout: QSApp.uiTimeout), "\(id): no Start Session")
        app.buttons["Start Session"].tap()
        XCTAssertTrue(questionCounter.waitForExistence(timeout: QSApp.uiTimeout), "\(id): quiz did not open")
        _ = optionButtons.firstMatch.waitForExistence(timeout: 4)
    }

    func optionFrames() -> [String: CGRect] {
        var frames: [String: CGRect] = [:]
        for index in 0..<optionButtons.count {
            let element = optionButtons.element(boundBy: index)
            frames[String(element.label.prefix(10))] = element.frame
        }
        return frames
    }

    /// Selects option `index` and submits; returns true when the answer was correct.
    @discardableResult
    func answer(option index: Int, _ id: String) -> Bool {
        let option = optionButtons.element(boundBy: index)
        XCTAssertTrue(option.waitForExistence(timeout: 6), "\(id): option \(index) missing")
        option.tap()
        XCTAssertTrue(submitButton.waitForExistence(timeout: 4) && submitButton.isEnabled, "\(id): Submit not enabled")
        submitButton.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "\(id): no reveal after Submit")
        return !app.element(labelled: "Your answer, incorrect").exists
    }

    func advance(_ id: String) {
        XCTAssertTrue(nextButton.waitForExistence(timeout: 4), "\(id): no Next question")
        nextButton.tap()
        Thread.sleep(forTimeInterval: 1.2)
    }

    /// Answers every remaining question with option 0 and returns the per-question outcomes.
    func finishQuiz(_ id: String, optionIndex: Int = 0, capture: Bool = true) -> [Bool] {
        var outcomes: [Bool] = []
        for step in 1...30 {
            guard questionCounter.waitForExistence(timeout: 5) else { break }
            let outcome = answer(option: min(optionIndex, max(optionButtons.count - 1, 0)), id)
            outcomes.append(outcome)
            if capture { shot(id, "q\(step)-reveal") }
            advance(id)
            if app.staticTexts["Session complete"].exists || app.buttons["One more session"].exists
                || text(containing: "Session complete").exists { break }
        }
        return outcomes
    }

    func labelsMatching(_ predicate: String) -> [String] {
        let query = app.descendants(matching: .any).matching(NSPredicate(format: predicate))
        var labels: [String] = []
        for index in 0..<min(query.count, 40) {
            let element = query.element(boundBy: index)
            if element.exists { labels.append(element.label) }
        }
        return labels
    }

    /// Library set tiles: a combined button labelled "<title>, N cards, ...".
    var libraryTileButtons: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label MATCHES '.*, [0-9]+ cards?, .*'"))
    }

    func openSettings(_ id: String) {
        goToToday()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 6), "\(id): no gear")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 6), "\(id): Settings did not open")
    }

    /// Drags the sheet from its top edge so a scrolled list underneath does not eat the swipe.
    func dismissSheet() {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        Thread.sleep(forTimeInterval: 1.2)
    }

    func writeText(_ text: String, to name: String) {
        try? text.write(to: Evidence.directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
}

import XCTest

/// Helpers for sections F (Lifecycle) and M (Matrix) of audit/e2e-test-script.md.
extension QSTestCase {
    var shortPasteNote: String {
        "Mitochondria are organelles that produce most of a cell's ATP through cellular respiration. They have a double membrane, and the folded inner membrane, called cristae, increases surface area. Mitochondria contain their own DNA, inherited from the mother."
    }

    /// Asks the host (fm.sh watcher) to fire a memory warning in the app, and waits for it to say it did.
    /// The runner cannot reach the Simulator menu, so the host does it with lldb.
    @discardableResult
    func requestMemoryWarning(_ id: String, timeout: TimeInterval = 90) -> Bool {
        let request = Evidence.directory.appendingPathComponent("memwarn-\(id).request")
        let done = Evidence.directory.appendingPathComponent("memwarn-\(id).done")
        try? FileManager.default.removeItem(at: done)
        try? "go".write(to: request, atomically: true, encoding: .utf8)
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if FileManager.default.fileExists(atPath: done.path) {
                Thread.sleep(forTimeInterval: 1.5)
                return true
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    /// Asks the host to take a `simctl io screenshot` named `<name>.png`. In landscape the runner's own screenshot comes back
    /// as the unrotated portrait framebuffer, so landscape evidence has to come from the host.
    func hostShot(_ id: String, _ name: String, timeout: TimeInterval = 20) {
        let base = Evidence.fileName("\(id)-\(name)-host")
        let request = Evidence.directory.appendingPathComponent("hostshot-\(base).request")
        let done = Evidence.directory.appendingPathComponent("hostshot-\(base).done")
        try? FileManager.default.removeItem(at: done)
        try? "go".write(to: request, atomically: true, encoding: .utf8)
        let end = Date().addingTimeInterval(timeout)
        while Date() < end, !FileManager.default.fileExists(atPath: done.path) { Thread.sleep(forTimeInterval: 0.3) }
    }

    /// Terminates and relaunches keeping disk state, then checks the first screen is not blank (waits for the 2 s white launch).
    func forceQuitAndRelaunch(_ id: String, name: String) {
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 1)
        shot(id, "\(name)-relaunch-early")
        let report = app.assertNotBlank("\(id)-\(name)-relaunch", in: self, timeout: 12)
        note(id, "\(name) relaunch: \(report.summary); labels \(app.labelSnapshot().sorted())")
        shot(id, "\(name)-relaunch")
    }

    /// Runner screenshot, plus a host screenshot on iPad where the runner's crop is the iPhone-sized window origin, not the window.
    func capture(_ id: String, _ name: String) {
        shot(id, name)
        if configLabel.hasPrefix("ipad") { hostShot(id, name) }
    }

    func settle(_ seconds: TimeInterval = 1.5) { Thread.sleep(forTimeInterval: seconds) }

    /// Taps Review on the status card, which sits above the set tiles and can scroll behind the nav bar at accessibility sizes.
    func openDraftReview(_ id: String) {
        openLibrary()
        let review = reviewCardButton
        XCTAssertTrue(review.waitForExistence(timeout: 8), "\(id): no status card with Review")
        var attempts = 0
        while !review.isHittable, attempts < 6 {
            app.swipeDown()
            settle(0.6)
            attempts += 1
        }
        tapReviewCard(id)
    }

    /// Opens the paste sheet, types the short note and starts a draft; returns once the status card shows drafting.
    func startShortGeneration(_ id: String) {
        chooseSource(id, label: Source.paste)
        typeIntoPasteSheet(id, text: shortPasteNote)
        tapDraftCards(id)
        XCTAssertTrue(waitForDrafting(id, timeout: 25), "\(id): drafting status never appeared")
        settle(2)
    }

    /// Answers with option A until one is wrong (at most `limit` questions). Returns the 1-based question number.
    func reachWrong(_ id: String, limit: Int = 6) -> Int? {
        for step in 1...limit {
            if !answer(option: 0, id) { return step }
            advance(id)
            if !questionCounter.exists { return nil }
        }
        return nil
    }

    /// Visible controls whose frame is not inside the app window, and visible buttons that are not hittable.
    func layoutProblems() -> [String] {
        let window = app.windows.firstMatch.frame
        var problems: [String] = []
        for kind in [XCUIElement.ElementType.button, .staticText, .textField, .textView, .switch] {
            let query = app.descendants(matching: kind)
            for index in 0..<min(query.count, 80) {
                let element = query.element(boundBy: index)
                guard element.exists, !element.label.isEmpty else { continue }
                let frame = element.frame
                if frame.isEmpty { continue }
                if frame.minX < window.minX - 1 || frame.maxX > window.maxX + 1 {
                    problems.append("horizontal overflow: \(kind.rawValue) '\(element.label.prefix(40))' \(frame.integral)")
                }
            }
        }
        return problems
    }

    func rotateAndSettle(_ id: String, name: String, to orientation: UIDeviceOrientation = .landscapeLeft) {
        XCUIDevice.shared.orientation = orientation
        settle(2.5)
        shot(id, name)
        hostShot(id, name)
        dump(id, name)
        let problems = layoutProblems()
        note(id, "\(name): window \(app.windows.firstMatch.frame.integral); \(problems.count) overflow: \(problems.prefix(8))")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "\(id): blank in landscape (\(name))")
    }

    func backToPortrait() {
        XCUIDevice.shared.orientation = .portrait
        settle(2)
    }

    var configLabel: String {
        ProcessInfo.processInfo.environment["QS_CONFIG"] ?? "default"
    }
}

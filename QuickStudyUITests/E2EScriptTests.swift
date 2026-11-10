import XCTest

/// One method per step of audit/e2e-test-script.md. Evidence is named `<step-id>-<short-name>`.
final class E2EScriptTests: QSTestCase {
    private struct Welcome {
        let exists: Bool
        let hittable: Bool
        let frame: CGRect
        let labelled: Int
        let pixelDeviation: Double
    }

    private func observeWelcome(_ app: XCUIApplication) -> Welcome {
        let button = app.buttons["Get Started"]
        let exists = button.exists
        let report = BlankScreenCheck.evaluate(app: app)
        return Welcome(
            exists: exists,
            hittable: exists && button.isHittable,
            frame: exists ? button.frame : .zero,
            labelled: report.labelledElementCount,
            pixelDeviation: report.pixelStandardDeviation
        )
    }

    // MARK: WS

    func test_WS_1() {
        XCUIDevice.shared.appearance = .light
        var failures: [String] = []
        for run in 1...3 {
            let app = launch(.freshInstall)
            Thread.sleep(forTimeInterval: 8)
            let seen = observeWelcome(app)
            app.screenshot(named: "WS-1-cold-\(run)", in: self)
            app.dumpHierarchy(named: "WS-1-cold-\(run)", in: self)
            add(XCTAttachment(string: "run \(run): \(seen)"))
            if !seen.exists || !seen.hittable || app.staticTexts["Notes in."].exists == false && app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Notes in'")).count == 0 {
                failures.append("run \(run): \(seen)")
            }
            app.terminate()
        }
        XCTAssertTrue(failures.isEmpty, "Welcome page not fully present: \(failures)")
    }

    func test_WS_2() {
        XCUIDevice.shared.appearance = .light
        let app = launch(.freshInstall)
        var timeline: [String] = []
        for (index, delay) in [0.0, 1, 2, 3, 5, 8].enumerated() {
            if delay > 0 { Thread.sleep(forTimeInterval: delay - [0.0, 1, 2, 3, 5, 8][index - 1]) }
            let seen = observeWelcome(app)
            timeline.append("t+\(delay)s exists=\(seen.exists) hittable=\(seen.hittable) labelled=\(seen.labelled) stddev=\(String(format: "%.1f", seen.pixelDeviation))")
            app.screenshot(named: "WS-2-t\(Int(delay))", in: self)
        }
        add(XCTAttachment(string: timeline.joined(separator: "\n")))
        try? timeline.joined(separator: "\n").write(
            to: Evidence.directory.appendingPathComponent("WS-2-timeline.txt"), atomically: true, encoding: .utf8)
        app.dumpHierarchy(named: "WS-2-hierarchy", in: self)

        let button = app.buttons["Get Started"]
        XCTAssertTrue(button.exists, "Get Started missing. \(timeline)")
        XCTAssertTrue(button.isHittable, "Get Started not hittable. frame \(button.frame)")
        let backBefore = app.buttons["Back"].isEnabled
        button.tap()
        Thread.sleep(forTimeInterval: 1.5)
        app.screenshot(named: "WS-2-after-tap", in: self)
        app.dumpHierarchy(named: "WS-2-after-tap", in: self)
        XCTAssertTrue(backBefore == false && app.buttons["Back"].isEnabled, "Page did not advance: Back still disabled")
    }

    func test_WS_3() {
        XCUIDevice.shared.appearance = .dark
        let app = launch(.freshInstall)
        Thread.sleep(forTimeInterval: 8)
        let seen = observeWelcome(app)
        app.screenshot(named: "WS-3-dark-cold", in: self)
        app.dumpHierarchy(named: "WS-3-dark-cold", in: self)
        XCTAssertTrue(seen.exists && seen.hittable, "Dark: Get Started present=\(seen.exists) hittable=\(seen.hittable)")
        XCTAssertGreaterThan(seen.pixelDeviation, 2)
    }

    /// Needs Reduce Motion on in the simulator (see Support/README.md); skips when the runner cannot see it.
    func test_WS_4() throws {
        try XCTSkipUnless(UIAccessibility.isReduceMotionEnabled, "BLOCKED: Reduce Motion is off in the simulator")
        let app = launch(.freshInstall)
        Thread.sleep(forTimeInterval: 8)
        let seen = observeWelcome(app)
        app.screenshot(named: "WS-4-reduce-motion", in: self)
        app.dumpHierarchy(named: "WS-4-reduce-motion", in: self)
        XCTAssertTrue(seen.exists && seen.hittable, "Reduce Motion: Get Started present=\(seen.exists) hittable=\(seen.hittable)")
        app.buttons["Get Started"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(app.buttons["Back"].isEnabled, "Reduce Motion: page did not advance")
    }

    /// Seed midDraft first.
    func test_WS_5() {
        launch(.midDraft)
        openLibrary()
        XCTAssertTrue(reviewCardButton.waitForExistence(timeout: 8), "No ready status card")
        shot("WS-5", "1-library-with-draft")
        tapReviewCard("WS-5")
        shot("WS-5", "2-review-cards")
        openSaveSheet("WS-5", cards: 6)
        shot("WS-5", "3-save-sheet")
        confirmSave(cards: 6)
        let watch = watchFrames("WS-5", "after-save", seconds: 4)
        shot("WS-5", "5-after-save")
        dump("WS-5", "5-after-save")
        XCTAssertEqual(watch.blankFrames, 0, "All-white frame after Save (\(watch.blankFrames) of \(watch.frames))")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after Save")
        XCTAssertTrue(app.staticTexts["Library"].exists || app.navigationBars["Library"].exists, "Not back on Library")
        let tile = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Water Cycle'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "New set not in Library")
        note("WS-5", "tile label: \(tile.label)")
        XCTAssertFalse(reviewCardButton.exists || readyCard.exists, "Ready card still present after save")
    }

    func test_WS_6() {
        launch(.midDraft)
        openLibrary()
        shot("WS-6", "1-library-with-draft")
        let alert = openDiscardAlert("WS-6")
        shot("WS-6", "2-confirmation")
        dump("WS-6", "2-confirmation")
        alert.buttons["Discard Draft"].tap()
        let watch = watchFrames("WS-6", "after-discard", seconds: 3)
        shot("WS-6", "3-after-discard")
        XCTAssertEqual(watch.blankFrames, 0, "All-white frame after discard")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        XCTAssertFalse(reviewCardButton.exists, "Ready card still there")
    }

    private func answerCurrentQuestion(_ id: String, index: Int) {
        let option = button(beginningWith: "Option ")
        XCTAssertTrue(option.waitForExistence(timeout: 8), "\(id): no options on question \(index)")
        option.tap()
        let submit = app.buttons["Submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5) && submit.isEnabled, "\(id): Submit not enabled")
        submit.tap()
    }

    private func finishSession(_ id: String) -> Int {
        var answered = 0
        for index in 1...30 {
            let counter = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Session, question'")).firstMatch
            guard counter.waitForExistence(timeout: 6) else { break }
            let before = counter.label
            answerCurrentQuestion(id, index: index)
            answered += 1
            let watch = watchFrames(id, "q\(index)-reveal", seconds: 1.5)
            XCTAssertEqual(watch.blankFrames, 0, "\(id): blank frame at reveal \(index) (\(before))")
            shot(id, "q\(index)-reveal")
            let reveal = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Why'")).firstMatch
            XCTAssertTrue(reveal.exists, "\(id): reveal missing on \(before). Popped?")
            let next = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Next' OR label BEGINSWITH 'Finish' OR label BEGINSWITH 'See' OR label BEGINSWITH 'Done'")).firstMatch
            XCTAssertTrue(next.waitForExistence(timeout: 4), "\(id): no next/finish button on \(before)")
            note(id, "q\(index) button: \(next.label); progress: \(String(describing: app.otherElements["Session progress"].value))")
            next.tap()
            Thread.sleep(forTimeInterval: 1)
            if text(containing: "Session complete").exists || app.buttons["One more session"].exists { break }
        }
        return answered
    }

    func test_WS_7() {
        launch(.demoData)
        app.tap("Start Session")
        let answered = finishSession("WS-7")
        note("WS-7", "answered \(answered)")
        let watch = watchFrames("WS-7", "after-last", seconds: 3)
        shot("WS-7", "session-complete")
        dump("WS-7", "session-complete")
        XCTAssertEqual(watch.blankFrames, 0, "Blank frame after last answer")
        XCTAssertTrue(text(containing: "Session complete").waitForExistence(timeout: 6), "Did not reach Session Complete (popped to Today?)")
        XCTAssertFalse(text(containing: "All caught up").exists, "Popped to All caught up")
    }

    func test_WS_8() {
        launch(.demoData)
        let weakest = button(beginningWith: "What is chlorophyll")
        XCTAssertTrue(weakest.waitForExistence(timeout: 8), "No WEAKEST CARD row")
        weakest.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("WS-8", "1-after-tap")
        dump("WS-8", "1-after-tap")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after weakest-card tap")
        answerCurrentQuestion("WS-8", index: 1)
        let watch = watchFrames("WS-8", "reveal", seconds: 2)
        shot("WS-8", "2-reveal")
        XCTAssertEqual(watch.blankFrames, 0)
        let next = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Next' OR label BEGINSWITH 'Finish' OR label BEGINSWITH 'See' OR label BEGINSWITH 'Done'")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 4), "No continue button after reveal")
        next.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("WS-8", "3-continue")
        dump("WS-8", "3-continue")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after continue")
    }

    func test_WS_9() {
        launch(.demoData)
        app.tap("Start Session")
        _ = finishSession("WS-9")
        XCTAssertTrue(text(containing: "Session complete").waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 2)
        shot("WS-9", "session-complete")
        dump("WS-9", "session-complete")
        for label in ["day streak", "CARDS", "CORRECT", "ACCURACY"] {
            XCTAssertTrue(text(containing: label).exists, "Session Complete missing '\(label)'")
        }
        let more = app.buttons["One more session"]
        XCTAssertTrue(more.exists, "No One more session")
        note("WS-9", "One more session hittable at rest: \(more.isHittable) frame \(more.frame)")
    }

    /// Needs the userSet seed: a saved, non-sample set, with onboarding done and release 1 seen.
    func test_WS_10() {
        app = QSApp.launch(states: [], extraArguments: ["-qs_hasCompletedOnboarding", "YES", "-qs_lastSeenRelease", "1"])
        Thread.sleep(forTimeInterval: 4)
        shot("WS-10", "launch")
        dump("WS-10", "launch")
        let labelled = BlankScreenCheck.evaluate(app: app)
        note("WS-10", labelled.summary)
        XCTAssertTrue(text(containing: "rebuilt around studying").exists || text(containing: "What's New").exists, "What's New not shown")
        XCTAssertFalse(labelled.isBlank, "Blank What's New")
    }

    // MARK: A

    private enum OnboardingPage: String, CaseIterable {
        case welcome = "Notes in."
        case howItWorks = "How it works"
        case aiIntro = "Private by default"
        case camera = "Snap your notes"
        case firstSource = "Let\u{2019}s make your first set"

        static let straightApostrophe = "Let's make your first set"
    }

    private func currentOnboardingPage() -> String? {
        let candidates: [(String, String)] = [
            ("welcome", "Get Started"),
            ("howItWorks", "How it works"),
            ("camera", "Snap your notes"),
            ("firstSource", "Let's make your first set"),
            ("aiIntro", "Continue")
        ]
        for (name, label) in candidates {
            if name == "aiIntro" {
                if app.buttons["Continue"].exists, !app.staticTexts["How it works"].exists, !app.staticTexts["Let's make your first set"].exists { return name }
            } else if app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", label)).firstMatch.exists || app.buttons[label].exists {
                return name
            }
        }
        return nil
    }

    private func advanceToFirstSource(_ id: String) {
        for step in 1...6 {
            if app.staticTexts["Let's make your first set"].waitForExistence(timeout: 1.5) { return }
            if app.buttons["Get Started"].exists {
                app.buttons["Get Started"].tap()
            } else if app.buttons["Continue"].exists {
                app.buttons["Continue"].tap()
            } else if app.buttons["Maybe later"].exists {
                app.buttons["Maybe later"].tap()
            } else {
                shot(id, "stuck-step\(step)")
                XCTFail("\(id): no advance control on step \(step)")
                return
            }
            Thread.sleep(forTimeInterval: 0.8)
        }
    }

    func test_A_1() {
        launch(.freshInstall)
        var centers: [Double] = []
        var pages: [String] = []
        var lcDone = false
        for step in 1...6 {
            Thread.sleep(forTimeInterval: 1)
            if let c = PageDots.activeDotCenter(in: app) { centers.append(c) }
            let page = currentOnboardingPage() ?? "unknown"
            pages.append(page)
            shot("A-1", "page\(step)-\(page)")
            let back = app.buttons["Back"]
            note("A-1", "page \(step) \(page): dot x=\(centers.last.map { String(format: "%.1f", $0) } ?? "nil") back enabled=\(back.exists && back.isEnabled)")
            if step == 1 { XCTAssertFalse(back.isEnabled, "Back enabled on page 1") }
            if step >= 2 { XCTAssertTrue(back.exists && back.isEnabled, "Back missing on page \(step)") }
            if step == 2, !lcDone {
                app.lifecycleCheckpoint("A-1", in: self)
                lcDone = true
            }
            if page == "firstSource" { break }
            if app.buttons["Get Started"].exists { app.buttons["Get Started"].tap() }
            else if app.buttons["Continue"].exists { app.buttons["Continue"].tap() }
            else if app.buttons["Maybe later"].exists { app.buttons["Maybe later"].tap() }
            else { XCTFail("A-1: no advance control on \(page)"); break }
        }
        note("A-1", "pages: \(pages), dot centres: \(centers)")
        XCTAssertEqual(pages.last, "firstSource", "Did not reach first-source page: \(pages)")
        XCTAssertEqual(pages.count, 5, "Expected 5 pages (camera undecided), saw \(pages)")
        XCTAssertEqual(centers.count, pages.count, "Active dot not found on every page")
        XCTAssertEqual(centers, centers.sorted(), "Dots do not track forward: \(centers)")
        XCTAssertEqual(Set(centers.map { Int($0) }).count, centers.count, "Dot did not move on every page: \(centers)")
    }

    func test_A_2() {
        launch(.freshInstall)
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 8))
        var forward: [Double] = []
        func dot() -> Double { PageDots.activeDotCenter(in: app) ?? -1 }
        forward.append(dot())
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 1.2)
        shot("A-2", "after-swipe-1")
        forward.append(dot())
        XCTAssertTrue(app.staticTexts["How it works"].exists, "Swipe did not reach How it works")
        XCTAssertTrue(app.buttons["Back"].isEnabled, "Back disabled after swipe")
        app.swipeLeft()
        Thread.sleep(forTimeInterval: 1.2)
        shot("A-2", "after-swipe-2")
        forward.append(dot())
        app.swipeRight()
        Thread.sleep(forTimeInterval: 1.2)
        shot("A-2", "after-swipe-back")
        let afterSwipeBack = dot()
        XCTAssertTrue(app.staticTexts["How it works"].exists, "Swipe back did not return to How it works")
        app.buttons["Back"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        shot("A-2", "after-back-button")
        let afterBack = dot()
        XCTAssertTrue(app.buttons["Get Started"].exists, "Back did not return to welcome")
        XCTAssertFalse(app.buttons["Back"].isEnabled, "Back still enabled on page 1")
        note("A-2", "forward dots \(forward), after swipe back \(afterSwipeBack), after Back \(afterBack)")
        XCTAssertEqual(forward, forward.sorted(), "Dots not in step on forward swipes")
        XCTAssertEqual(Int(afterSwipeBack), Int(forward[1]), "Dot out of sync after swipe back")
        XCTAssertEqual(Int(afterBack), Int(forward[0]), "Dot out of sync after Back")
    }

    func test_A_3() {
        launch(.freshInstall)
        advanceOnboarding()
        let later = app.buttons["Maybe later"]
        XCTAssertTrue(later.waitForExistence(timeout: 6), "No camera page (camera already decided?)")
        shot("A-3", "camera-page")
        later.tap()
        XCTAssertTrue(app.staticTexts["Let's make your first set"].waitForExistence(timeout: 5), "Maybe later did not advance")
        shot("A-3", "later-advanced")
        app.terminate()

        launch(.freshInstall)
        advanceOnboarding()
        let allow = app.buttons["Allow camera access"]
        XCTAssertTrue(allow.waitForExistence(timeout: 6), "No Allow camera access on second run")
        allow.tap()
        let handled = SystemAlerts.handle(.allow, timeout: 6)
        note("A-3", "system alert handled: \(handled)")
        shot("A-3", "after-allow-tap")
        XCTAssertTrue(app.staticTexts["Let's make your first set"].waitForExistence(timeout: 8), "Allow did not advance (hang?)")
        shot("A-3", "allow-advanced")
    }

    private func firstSourceRun(_ id: String, option: String, name: String) {
        launch(.freshInstall)
        advanceToFirstSource(id)
        XCTAssertTrue(app.staticTexts["Let's make your first set"].exists)
        shot(id, "\(name)-source-page")
        dump(id, "\(name)-source-page")
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", option)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 4), "\(id): no option '\(option)'")
        row.tap()
        Thread.sleep(forTimeInterval: 3.5)
        shot(id, "\(name)-after-choice")
        dump(id, "\(name)-after-choice")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "\(id) \(name): blank after choice")
        XCTAssertFalse(app.buttons["Not Now"].exists, "\(id) \(name): cloud consent asked before a source was read")
    }

    func test_A_4() {
        firstSourceRun("A-4", option: "Paste text", name: "paste")
        XCTAssertTrue(app.navigationBars["Paste Text"].exists && app.textViews.firstMatch.exists, "Paste: no Paste Text sheet")
        app.terminate()
        firstSourceRun("A-4", option: "Drop in a PDF", name: "pdf")
        let pickerOpen = filesPicker.waitForExistence(timeout: 8)
        note("A-4", "pdf: Files picker visible=\(pickerOpen)")
        XCTAssertTrue(pickerOpen, "PDF: Files picker did not open")
        app.terminate()
        firstSourceRun("A-4", option: "Try a demo set", name: "demo")
        XCTAssertTrue(app.buttons["Start Session"].waitForExistence(timeout: 6) || text(containing: "TODAY'S SESSION").exists, "Demo: sample set not on Today")
        app.terminate()
        firstSourceRun("A-4", option: "Scan a page", name: "scan")
        note("A-4", "scan labels: \(app.labelSnapshot().sorted())")
        let alert = app.alerts["Camera Unavailable"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "Scan: no Camera Unavailable alert on a simulator")
        alert.buttons["OK"].tap()
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Scan: blank after dismissing the alert")
    }

    /// Paste the short note, draft it, save it, and expect the paywall afterwards.
    func test_A_5() {
        launch(.freshInstall)
        advanceToFirstSource("A-5")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Paste text'")).firstMatch.tap()
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 8), "No paste editor")
        editor.tap()
        editor.typeText("Mitochondria are organelles that produce most of a cell's ATP through cellular respiration. They have a double membrane, and the folded inner membrane, called cristae, increases surface area. Mitochondria contain their own DNA, inherited from the mother.")
        shot("A-5", "1-typed")
        tapDraftCards("A-5")
        let (outcome, seconds) = awaitGenerationOutcome("A-5")
        note("A-5", "outcome \(outcome) after \(Int(seconds)) s")
        XCTAssertEqual(outcome, .ready, "First draft did not become ready")
        shot("A-5", "2-ready-card")
        tapReviewCard("A-5")
        saveDraftAsNewSet("A-5")
        Thread.sleep(forTimeInterval: 3)
        shot("A-5", "3-after-save")
        dump("A-5", "3-after-save")
        let watch = watchFrames("A-5", "paywall", seconds: 3)
        XCTAssertEqual(watch.blankFrames, 0)
        let paywall = text(containing: "QuickStudy Pro").exists || app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Subscribe' OR label CONTAINS[c] 'free trial'")).firstMatch.exists
        XCTAssertTrue(paywall, "Paywall did not present after the first set")
    }

    func test_A_6() {
        launch(.onboardedEmpty)
        XCTAssertTrue(app.staticTexts["Build your first set"].waitForExistence(timeout: 8))
        shot("A-6", "today-empty")
        dump("A-6", "today-empty")
        XCTAssertTrue(app.buttons["Settings"].exists, "No gear (Settings)")
        XCTAssertFalse(app.buttons["Edit"].exists, "Edit button present")
        let pill = app.buttons.matching(NSPredicate(format: "label CONTAINS 'generations' OR label CONTAINS 'free'")).firstMatch
        // By design: the generations pill is hidden on an empty Today, where "Go to Library" is the only action.
        XCTAssertFalse(pill.exists, "Generations pill shown on an empty Today. Labels: \(app.labelSnapshot().sorted())")
        let cta = app.buttons["Go to Library"]
        XCTAssertTrue(cta.exists && cta.isEnabled, "Go to Library missing or disabled")
        let labels = app.labelSnapshot().map { $0.lowercased() }
        for apology in ["sorry", "unfortunately", "oops", "nothing here"] {
            XCTAssertFalse(labels.contains { $0.contains(apology) }, "Apologetic copy '\(apology)'")
        }
        app.lifecycleCheckpoint("A-6", in: self)
        shot("A-6", "after-lc")
    }

    func test_A_7() {
        launch(.onboardedEmpty)
        app.tapTab("Library")
        XCTAssertTrue(app.staticTexts["Build your first set"].waitForExistence(timeout: 8))
        shot("A-7", "library-empty")
        dump("A-7", "library-empty")
        XCTAssertTrue(app.staticTexts["Tap + to scan, import or paste your first notes."].exists, "Empty state does not point at +")
        XCTAssertTrue(app.element(labelContaining: "1 to 10 pages of notes").exists, "No page-count tip")
        let create = createButton
        XCTAssertTrue(create.exists && create.isHittable, "Floating create button missing or not hittable")
        app.lifecycleCheckpoint("A-7", in: self)
        shot("A-7", "after-lc")
    }

    func test_A_8() {
        launch(.freshInstall)
        advanceToFirstSource("A-8")
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Try a demo set'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["Start Session"].waitForExistence(timeout: 8))
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 4)
        shot("A-8", "after-relaunch")
        dump("A-8", "after-relaunch")
        XCTAssertFalse(app.buttons["Get Started"].exists, "Onboarding shown again")
        XCTAssertTrue(app.buttons["Start Session"].exists || app.staticTexts["Today"].exists, "Not on Today after relaunch")
    }
}

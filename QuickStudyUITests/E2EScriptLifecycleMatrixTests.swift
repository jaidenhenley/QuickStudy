import XCTest

/// Sections F (Lifecycle) and M (Matrix) of audit/e2e-test-script.md.
/// F: seed `midDraft` first (draft file) and launch with demo data. M: `test_M_corePath` is driven by fm.sh, which sets the
/// device configuration and passes `QS_CONFIG` (evidence label) through TEST_RUNNER_QS_CONFIG.
final class E2EScriptLifecycleMatrixTests: QSTestCase {
    // MARK: F-1 memory warning

    func test_F_1() {
        launch(.demoData)
        settle(2)
        goToToday()
        shot("F-1", "0-today-before")
        let todayBefore = app.labelSnapshot()
        let fired = requestMemoryWarning("F-1-today")
        note("F-1", "today: warning fired by host: \(fired)")
        XCTAssertTrue(fired, "host did not fire the memory warning")
        shot("F-1", "1-today-after")
        XCTAssertEqual(app.state, .runningForeground, "app not running after warning on Today")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank on Today after warning")
        XCTAssertGreaterThan(Double(todayBefore.intersection(app.labelSnapshot()).count) / Double(max(todayBefore.count, 1)), 0.8, "Today changed after warning")

        startSessionFromToday("F-1")
        optionButtons.element(boundBy: 1).tap()
        settle(0.8)
        let quizBefore = app.labelSnapshot()
        shot("F-1", "2-quiz-before")
        let firedQuiz = requestMemoryWarning("F-1-quiz")
        note("F-1", "quiz: warning fired by host: \(firedQuiz)")
        XCTAssertTrue(firedQuiz)
        shot("F-1", "3-quiz-after")
        XCTAssertEqual(app.state, .runningForeground, "app not running after warning in quiz")
        XCTAssertTrue(questionCounter.exists, "quiz left after warning")
        XCTAssertTrue(optionButtons.element(boundBy: 1).isSelected, "selection lost after warning")
        XCTAssertGreaterThan(Double(quizBefore.intersection(app.labelSnapshot()).count) / Double(max(quizBefore.count, 1)), 0.8, "quiz changed after warning")
        submitButton.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "cannot Submit after warning")

        app.terminate()
        app.relaunchKeepingState()
        settle(3)
        openDraftReview("F-1")
        let reviewBefore = app.labelSnapshot()
        shot("F-1", "4-review-before")
        let firedReview = requestMemoryWarning("F-1-review")
        note("F-1", "review: warning fired by host: \(firedReview)")
        XCTAssertTrue(firedReview)
        shot("F-1", "5-review-after")
        XCTAssertEqual(app.state, .runningForeground, "app not running after warning in Review")
        XCTAssertTrue(button(beginningWith: "Save ").exists, "Review lost after warning")
        XCTAssertGreaterThan(Double(reviewBefore.intersection(app.labelSnapshot()).count) / Double(max(reviewBefore.count, 1)), 0.8, "Review changed after warning")
    }

    // MARK: F-2 force quit and relaunch

    func test_F_2_library() {
        launch(.demoData)
        settle(2)
        openLibrary()
        shot("F-2", "library-before")
        forceQuitAndRelaunch("F-2", name: "library")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 8), "no tab bar after relaunch")
        goToToday()
        openLibrary()
        XCTAssertTrue(libraryTileButtons.firstMatch.waitForExistence(timeout: 5), "Library tiles missing after relaunch")
        shot("F-2", "library-after")
    }

    func test_F_2_quiz() {
        launch(.demoData)
        goToToday()
        let before = todayCardCount()
        startSessionFromToday("F-2")
        let correct = answer(option: 0, "F-2")
        advance("F-2")
        shot("F-2", "quiz-before")
        forceQuitAndRelaunch("F-2", name: "quiz")
        let after = todayCardCount()
        note("F-2", "quiz (terminate without backgrounding): due before \(String(describing: before)), after relaunch \(String(describing: after)), first answer correct \(correct); quiz visible \(questionCounter.exists)")
        XCTAssertFalse(questionCounter.exists, "unexpected quiz resume")
        XCTAssertNotNil(after, "Today did not show a session card after relaunch")
        shot("F-2", "quiz-after")
    }

    func test_F_2_quizBackgrounded() {
        launch(.demoData)
        goToToday()
        let before = todayCardCount()
        startSessionFromToday("F-2b")
        let correct = answer(option: 0, "F-2b")
        advance("F-2b")
        XCUIDevice.shared.press(.home)
        settle(2)
        forceQuitAndRelaunch("F-2b", name: "quiz-backgrounded")
        let after = todayCardCount()
        note("F-2b", "quiz (Home then terminate, like the app switcher): due before \(String(describing: before)), after relaunch \(String(describing: after)), first answer correct \(correct)")
        XCTAssertNotNil(after)
    }

    func test_F_2_review() {
        launch(.demoData)
        settle(2)
        openDraftReview("F-2")
        shot("F-2", "review-before")
        forceQuitAndRelaunch("F-2", name: "review")
        openLibrary()
        XCTAssertTrue(app.buttons["Resume draft"].waitForExistence(timeout: 8), "draft row missing after killing in Review")
        shot("F-2", "review-after")
    }

    func test_F_2_paywall() {
        launch(.demoData)
        goToToday()
        let pill = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'free generations left'")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 6), "no generations pill: \(app.labelSnapshot().sorted())")
        pill.tap()
        settle(3)
        XCTAssertTrue(text(containing: "QuickStudy Pro").exists, "paywall did not open")
        shot("F-2", "paywall-before")
        forceQuitAndRelaunch("F-2", name: "paywall")
        XCTAssertFalse(text(containing: "Pro Monthly").exists && app.buttons["Restore Subscription"].exists, "paywall came back after relaunch")
        shot("F-2", "paywall-after")
    }

    func test_F_2_generating() {
        launch(.onboardedEmpty)
        startShortGeneration("F-2")
        shot("F-2", "generating-before")
        forceQuitAndRelaunch("F-2", name: "generating")
        settle(2)
        XCTAssertFalse(generatingVisible, "Generating came back after relaunch")
        openLibrary()
        note("F-2", "generating: after relaunch Library labels \(app.labelSnapshot().sorted())")
        shot("F-2", "generating-after-library")
    }

    // MARK: F-3 appearance change while backgrounded

    func test_F_3() {
        XCUIDevice.shared.appearance = .light
        launch(.demoData)
        settle(2)
        shot("F-3", "0-today-light")
        for (index, target) in [(1, XCUIDevice.Appearance.dark), (2, .light)] {
            XCUIDevice.shared.press(.home)
            settle(2)
            XCUIDevice.shared.appearance = target
            settle(2)
            app.activate()
            let watch = watchFrames("F-3", "return-\(index)", seconds: 3)
            note("F-3", "background -> \(target == .dark ? "dark" : "light"): \(watch.blankFrames) blank frames of \(watch.frames)")
            shot("F-3", "\(index)-today-\(target == .dark ? "dark" : "light")")
            XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank after appearance change")
        }
        openLibrary()
        shot("F-3", "3-library-light")
        XCUIDevice.shared.press(.home)
        settle(1.5)
        XCUIDevice.shared.appearance = .dark
        settle(1.5)
        app.activate()
        settle(2)
        shot("F-3", "4-library-dark")
        app.buttons["New set"].tap()
        settle(1.5)
        XCUIDevice.shared.press(.home)
        settle(1.5)
        XCUIDevice.shared.appearance = .light
        settle(1.5)
        app.activate()
        settle(2)
        shot("F-3", "5-newset-sheet-light")
        dump("F-3", "5-newset-sheet-light")
    }

    // MARK: F-4 landscape

    func test_F_4() {
        launch(.demoData)
        settle(2)
        goToToday()
        rotateAndSettle("F-4", name: "1-today-landscape")
        backToPortrait()
        openLibrary()
        rotateAndSettle("F-4", name: "2-library-landscape")
        backToPortrait()

        openDraftReview("F-4")
        rotateAndSettle("F-4", name: "3-review-landscape")
        backToPortrait()
        app.terminate()
        app.relaunchKeepingState()
        settle(3)

        goToToday()
        startSessionFromToday("F-4")
        rotateAndSettle("F-4", name: "4-quiz-landscape")
        let optionsInLandscape = optionButtons.count
        let submitHittable = submitButton.exists && submitButton.isHittable
        note("F-4", "quiz landscape: options \(optionsInLandscape), Submit hittable \(submitHittable)")
        backToPortrait()
        _ = finishQuiz("F-4", capture: false)
        settle(2.5)
        XCTAssertTrue(text(containing: "Session complete").exists, "Session Complete not reached")
        rotateAndSettle("F-4", name: "5-complete-landscape")
        let more = app.buttons["One more session"]
        note("F-4", "complete landscape: One more session exists \(more.exists) hittable \(more.isHittable)")
        backToPortrait()
    }

    // MARK: M core path

    /// launch -> Today -> Library -> New Set sheet -> Review drafts -> first quiz question -> wrong answer -> Session Complete -> Settings -> Paywall.
    /// Needs `seed.sh <udid> midDraft` first (draft file); demo mode supplies the quiz data.
    func test_M_corePath() {
        let id = "M-\(configLabel)"
        launch(.demoData)
        note(id, "config \(configLabel): reduceMotion=\(UIAccessibility.isReduceMotionEnabled) reduceTransparency=\(UIAccessibility.isReduceTransparencyEnabled) boldText=\(UIAccessibility.isBoldTextEnabled) window=\(app.windows.firstMatch.frame.integral)")
        Thread.sleep(forTimeInterval: 0.3)
        capture(id, "00-launch-early")
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 12), "Today not shown")
        settle(2)
        capture(id, "01-today")
        dump(id, "01-today")
        note(id, "today problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(1)
        capture(id, "02-today-scrolled")
        app.swipeDown()

        openLibrary()
        settle(1.2)
        capture(id, "03-library")
        dump(id, "03-library")
        note(id, "library problems: \(layoutProblems().prefix(8))")

        app.buttons["New set"].tap()
        XCTAssertTrue(app.staticTexts["Capture a page and cards draft automatically."].waitForExistence(timeout: QSApp.uiTimeout), "New set sheet did not open")
        settle(1.2)
        capture(id, "04-new-set-sheet")
        dump(id, "04-new-set-sheet")
        note(id, "sheet problems: \(layoutProblems().prefix(8))")
        if app.buttons["Cancel"].exists { app.buttons["Cancel"].tap() } else { dismissSheet() }
        settle(1.2)

        XCTAssertTrue(app.buttons["Resume draft"].waitForExistence(timeout: 8), "no pending draft row (seed midDraft first)")
        capture(id, "05-library-draft-row")
        tapResumeDraft(id)
        settle(1.5)
        capture(id, "06-scan-preview")
        continueToReviewDrafts(id)
        settle(1)
        capture(id, "07-review-drafts")
        dump(id, "07-review-drafts")
        note(id, "review problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(0.8)
        capture(id, "08-review-drafts-scrolled")
        app.swipeDown()
        app.terminate()
        app.relaunchKeepingState()
        settle(3)

        goToToday()
        startSessionFromToday(id)
        settle(1)
        capture(id, "09-quiz-first-question")
        dump(id, "09-quiz-first-question")
        note(id, "quiz problems: \(layoutProblems().prefix(8))")
        optionButtons.element(boundBy: 1).tap()
        settle(0.8)
        capture(id, "10-quiz-option-selected")
        _ = reachWrong(id) ?? 0
        settle(1.2)
        capture(id, "11-quiz-wrong-answer")
        dump(id, "11-quiz-wrong-answer")
        note(id, "wrong problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(0.8)
        capture(id, "12-quiz-wrong-answer-scrolled")
        app.swipeDown()
        if nextButton.exists { advance(id) }
        if questionCounter.exists { _ = finishQuiz(id, capture: false) }
        settle(2.5)
        XCTAssertTrue(text(containing: "Session complete").exists, "Session Complete not reached")
        capture(id, "13-session-complete")
        dump(id, "13-session-complete")
        note(id, "complete problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(0.8)
        capture(id, "14-session-complete-scrolled")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        settle(1.5)

        openSettings(id)
        settle(1)
        capture(id, "15-settings")
        dump(id, "15-settings")
        note(id, "settings problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(0.8)
        capture(id, "16-settings-scrolled")
        let upgrade = app.buttons["Upgrade to QuickStudy Pro"]
        for attempt in 0..<6 where !(upgrade.exists && upgrade.isHittable) {
            if attempt < 3 { app.swipeDown() } else { app.swipeUp() }
            settle(0.5)
        }
        XCTAssertTrue(upgrade.waitForExistence(timeout: 5), "no upgrade row: \(app.labelSnapshot().sorted())")
        upgrade.tap()
        settle(3.5)
        capture(id, "17-paywall")
        dump(id, "17-paywall")
        note(id, "paywall problems: \(layoutProblems().prefix(8))")
        app.swipeUp()
        settle(0.8)
        capture(id, "18-paywall-scrolled")
    }
}

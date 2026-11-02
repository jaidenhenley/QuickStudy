import XCTest

/// Sections D (Quiz) and E (Library, set detail, streaks, settings, paywall, consent) of audit/e2e-test-script.md.
/// One method per step. Seeds: demoData for D; sessions / userSet / onboardedEmpty for E (see each method).
final class E2EScriptQuizLibraryTests: QSTestCase {
    // MARK: D. Quiz (seed demoData)

    func test_D_1() {
        launch(.demoData)
        let before = todayCardCount()
        note("D-1", "Today session count before: \(String(describing: before))")
        shot("D-1", "0-today")
        startSessionFromToday("D-1")
        Thread.sleep(forTimeInterval: 1)
        shot("D-1", "1-first-question")
        dump("D-1", "1-first-question")

        let position = sessionPosition()
        XCTAssertEqual(position?.index, 1, "counter should read question 1")
        note("D-1", "counter label: \(questionCounter.label)")
        XCTAssertEqual(position?.total, before, "session length should equal Today's count")
        XCTAssertTrue(app.otherElements["Elapsed time"].exists || app.staticTexts["Elapsed time"].exists
                      || app.element(labelled: "Elapsed time").exists, "no elapsed timer")
        let progress = app.element(labelled: "Session progress")
        XCTAssertTrue(progress.exists, "no segmented progress bar")
        note("D-1", "progress value: \(String(describing: progress.value))")
        let why = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Why this answer'")).firstMatch
        note("D-1", "Why pill before Submit: exists \(why.exists) hittable \(why.isHittable)")
        XCTAssertFalse(why.exists && why.isHittable, "the Why? pill (it quotes the source) must be hidden until the answer is submitted")
        XCTAssertTrue(text(containing: "Photosynthesis").exists, "no category label")
        XCTAssertEqual(optionButtons.count, 4, "expected 4 options")
        XCTAssertTrue(submitButton.exists && !submitButton.isEnabled, "Submit should exist and be disabled")
        let hint = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'hint'")).firstMatch
        XCTAssertFalse(hint.exists, "there is no hint button; the Why? pill after Submit is the only source affordance")
        _ = answer(option: 0, "D-1")
        XCTAssertTrue(why.waitForExistence(timeout: 4) && why.isHittable, "Why? pill not available after Submit")
        note("D-1", "Why pill after Submit: \(why.label), hittable \(why.isHittable)")
    }

    func test_D_2() {
        launch(.demoData)
        startSessionFromToday("D-2")
        Thread.sleep(forTimeInterval: 1.2)
        let before = optionFrames()
        let promptFrame = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH '?'")).firstMatch.frame
        let submitBefore = submitButton.frame
        let why = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Why this answer'")).firstMatch
        shot("D-2", "1-before")
        for index in 0..<optionButtons.count {
            optionButtons.element(boundBy: index).tap()
            Thread.sleep(forTimeInterval: 0.9)
            shot("D-2", "2-selected-\(index)")
            let after = optionFrames()
            let selected = optionButtons.element(boundBy: index)
            note("D-2", "option \(index) isSelected=\(selected.isSelected) submitEnabled=\(submitButton.isEnabled)")
            XCTAssertTrue(selected.isSelected, "option \(index) not selected")
            for (key, frame) in before {
                guard let moved = after[key] else { XCTFail("option \(key) vanished"); continue }
                if abs(moved.minX - frame.minX) > 0.5 || abs(moved.minY - frame.minY) > 0.5
                    || abs(moved.width - frame.width) > 0.5 || abs(moved.height - frame.height) > 0.5 {
                    note("D-2", "REFLOW option \(key) selecting \(index): \(frame) -> \(moved)")
                    XCTFail("Option \(key) reflowed selecting \(index): \(frame) -> \(moved)")
                }
            }
            let promptAfter = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH '?'")).firstMatch.frame
            XCTAssertEqual(promptAfter, promptFrame, "prompt moved")
            XCTAssertEqual(submitButton.frame, submitBefore, "Submit moved")
            XCTAssertFalse(why.exists && why.isHittable, "Why pill became available by selecting an option")
        }
        note("D-2", "frames before: \(before)")
        XCTAssertTrue(submitButton.isEnabled)
    }

    func test_D_3() {
        launch(.demoData)
        startSessionFromToday("D-3")
        var correct = answer(option: 0, "D-3")
        if !correct {
            let correctText = app.element(labelled: "Correct answer").value as? String ?? ""
            note("D-3", "option A was wrong; correct text: \(correctText)")
            shot("D-3", "0-wrong-first")
            app.buttons["Undo"].tap()
            Thread.sleep(forTimeInterval: 1)
            var picked = false
            for index in 0..<optionButtons.count where optionButtons.element(boundBy: index).label.hasSuffix(correctText) {
                correct = answer(option: index, "D-3")
                picked = true
                break
            }
            XCTAssertTrue(picked, "could not find the correct option after Undo")
        }
        Thread.sleep(forTimeInterval: 1)
        shot("D-3", "1-correct")
        dump("D-3", "1-correct")
        XCTAssertTrue(correct, "should be correct")
        XCTAssertTrue(app.element(labelled: "Correct").exists, "no Correct state")
        XCTAssertFalse(app.element(labelled: "Your answer, incorrect").exists)
        XCTAssertTrue(app.element(labelled: "Why").exists || text(containing: "Why").exists, "no Why card")
        XCTAssertFalse(app.buttons["Undo"].exists, "Undo shown on a correct answer")
        let index = sessionPosition()?.index
        advance("D-3")
        XCTAssertEqual(sessionPosition()?.index, (index ?? 0) + 1, "did not advance")
        shot("D-3", "2-next")
    }

    /// Answers with option A on each question until one is wrong. Returns the question index.
    private func reachWrongAnswer(_ id: String) -> Int? {
        for step in 1...6 {
            let correct = answer(option: 0, id)
            if !correct { return step }
            advance(id)
            if !questionCounter.exists { return nil }
        }
        return nil
    }

    func test_D_4() {
        launch(.demoData)
        startSessionFromToday("D-4")
        guard let step = reachWrongAnswer("D-4") else { return XCTFail("every option A was correct") }
        Thread.sleep(forTimeInterval: 1.2)
        shot("D-4", "1-wrong")
        dump("D-4", "1-wrong")
        note("D-4", "wrong at question \(step)")
        XCTAssertTrue(app.element(labelled: "Your answer, incorrect").exists, "no red YOUR ANSWER card")
        XCTAssertTrue(app.element(labelled: "Correct answer").exists, "no green CORRECT card")
        XCTAssertTrue(text(containing: "Why").exists, "no Why")
        let source = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Source: '")).firstMatch
        XCTAssertTrue(source.exists, "no source line")
        note("D-4", "source label: \(source.label)")
        XCTAssertTrue(source.label.contains("Photosynthesis") && source.label.lowercased().contains("page"),
                      "source lacks document/page: \(source.label)")
        let surface = text(containing: "again tomorrow")
        XCTAssertTrue(surface.exists, "no 'We'll surface this one again tomorrow.'")
        note("D-4", "surface label: \(surface.label)")
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.exists, "no Undo")
        note("D-4", "Undo hittable: \(undo.isHittable) frame \(undo.frame); Next frame \(nextButton.frame); screen \(app.frame)")
        XCTAssertEqual(text(containing: "again tomorrow").label.contains("·"), false)
    }

    func test_D_5() {
        launch(.demoData)
        goToToday()
        let todayBefore = app.labelSnapshot().filter { $0.contains("cards,") || $0.contains("Missed") }.sorted()
        let streakBefore = text(containing: "day streak").exists
        note("D-5", "Today before: \(todayBefore) streak link: \(streakBefore)")
        startSessionFromToday("D-5")
        guard let step = reachWrongAnswer("D-5") else { return XCTFail("every option A was correct") }
        note("D-5", "wrong at q\(step)")
        shot("D-5", "1-wrong")
        let position = sessionPosition()?.index
        app.buttons["Undo"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        shot("D-5", "2-after-undo")
        dump("D-5", "2-after-undo")
        XCTAssertEqual(sessionPosition()?.index, position, "question changed after Undo")
        XCTAssertFalse(nextButton.exists, "still revealed after Undo")
        XCTAssertTrue(submitButton.exists && !submitButton.isEnabled, "Submit should be disabled, nothing selected")
        XCTAssertFalse(optionButtons.allElementsBoundByIndex.contains { $0.isSelected }, "an option is still selected")
        XCTAssertFalse(app.element(labelled: "Your answer, incorrect").exists)
        let progressValue = "\(String(describing: app.element(labelled: "Session progress").value))"
        note("D-5", "progress after undo: \(progressValue)")
        XCTAssertTrue(progressValue.contains("0 missed") || step > 1, "wrong segment still red: \(progressValue)")
        // Leave without answering anything else; box and counts must match the start.
        backButton.tap()
        Thread.sleep(forTimeInterval: 1.5)
        goToToday()
        let todayAfter = app.labelSnapshot().filter { $0.contains("cards,") || $0.contains("Missed") }.sorted()
        note("D-5", "Today after: \(todayAfter)")
        if step == 1 {
            XCTAssertEqual(todayAfter, todayBefore, "Today changed after wrong+Undo+leave")
        } else {
            note("D-5", "q\(step - 1) earlier answers were correct and are persisted; compare is partial")
        }
    }

    func test_D_6() {
        launch(.demoData)
        startSessionFromToday("D-6")
        let why = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Why this answer'")).firstMatch
        let index = sessionPosition()?.index
        let prompt = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH '?'")).firstMatch.label
        XCTAssertFalse(why.exists && why.isHittable, "Why? available before Submit")
        _ = answer(option: 0, "D-6")
        XCTAssertTrue(why.waitForExistence(timeout: 4) && why.isHittable, "Why? not available after Submit")
        XCTAssertEqual(why.value as? String, "Hidden")
        let before = Set(app.staticTexts.allElementsBoundByIndex.map(\.label).filter { $0.count > 60 })
        why.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("D-6", "1-why-open")
        dump("D-6", "1-why-open")
        note("D-6", "Why value after tap: \(String(describing: why.value)); sheets: \(app.sheets.count)")
        XCTAssertEqual(why.value as? String, "Shown", "Why? did not expand")
        let excerpts = Set(app.staticTexts.allElementsBoundByIndex.map(\.label).filter { $0.count > 60 }).subtracting(before)
        note("D-6", "new long texts: \(excerpts)")
        XCTAssertFalse(excerpts.isEmpty, "no source excerpt visible")
        why.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("D-6", "2-why-closed")
        XCTAssertEqual(why.value as? String, "Hidden")
        XCTAssertEqual(sessionPosition()?.index, index, "question changed")
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label ENDSWITH '?'")).firstMatch.label, prompt)
        // Open it and advance: the excerpt must reset on the next question.
        why.tap()
        advance("D-6")
        XCTAssertFalse(why.exists && why.isHittable, "Why? available on the next question before Submit")
        _ = answer(option: 0, "D-6")
        XCTAssertEqual(why.value as? String, "Hidden", "excerpt stayed open on the next question")
    }

    func test_D_7() {
        launch(.demoData)
        startSessionFromToday("D-7")
        let hint = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'hint'")).firstMatch
        XCTAssertFalse(hint.exists, "there is no hint button")
        let why = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Why this answer'")).firstMatch
        XCTAssertFalse(why.exists && why.isHittable, "Why? pill reachable before Submit; its excerpt would reveal the answer")
        shot("D-7", "1-before-submit")
        let before = Set(app.staticTexts.allElementsBoundByIndex.map(\.label).filter { $0.count > 60 })
        _ = answer(option: 0, "D-7")
        XCTAssertTrue(why.waitForExistence(timeout: 4) && why.isHittable, "Why? pill not available after Submit")
        XCTAssertEqual(why.value as? String, "Hidden", "source excerpt open before the pill is tapped")
        why.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("D-7", "2-why-open")
        XCTAssertEqual(why.value as? String, "Shown", "Why? pill did not open")
        let after = Set(app.staticTexts.allElementsBoundByIndex.map(\.label).filter { $0.count > 60 })
        let excerpts = after.subtracting(before)
        note("D-7", "excerpt candidates after tap: \(excerpts)")
        XCTAssertFalse(excerpts.isEmpty, "tapping Why? after Submit showed no source excerpt")
    }

    func test_D_8() {
        launch(.demoData)
        let initial = todayCardCount() ?? -1
        note("D-8", "initial due: \(initial)")
        startSessionFromToday("D-8")
        optionButtons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertTrue(app.lifecycleCheckpoint("D-8", in: self), "LC failed mid-question")
        shot("D-8", "1-after-LC")
        let stillSelected = optionButtons.element(boundBy: 1).isSelected
        note("D-8", "selection survived LC: \(stillSelected); submit enabled: \(submitButton.isEnabled); counter \(questionCounter.label)")
        XCTAssertTrue(stillSelected, "selection lost after Home/activate")
        // Answer q1 and q2, background once (a user swiping the app away backgrounds first), answer q3, then hard kill.
        submitButton.tap()
        XCTAssertTrue(nextButton.waitForExistence(timeout: 4))
        advance("D-8")
        answer(option: 0, "D-8")
        advance("D-8")
        XCTAssertTrue(app.lifecycleCheckpoint("D-8b", in: self), "LC failed after answers")
        answer(option: 0, "D-8")
        shot("D-8", "2-before-kill")
        note("D-8", "answered 3; question 3 revealed without any background after it; killing")
        app.terminate()
        Thread.sleep(forTimeInterval: 1)
        app.launchArguments.removeAll { $0 == QSApp.resetArgument }
        app.launch()
        Thread.sleep(forTimeInterval: 3)
        shot("D-8", "3-after-relaunch")
        dump("D-8", "3-after-relaunch")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank after relaunch")
        let after = todayCardCount()
        note("D-8", "due after relaunch: \(String(describing: after)) (expected \(initial - 2): the third answer was never flushed)")
        XCTAssertNotNil(after, "Today not shown after relaunch")
        // By design: persistence is batched and flushes on backgrounding or session end, so a kill with no backgrounding loses the answers since the last flush.
        XCTAssertEqual(after, initial - 2, "answers flushed by backgrounding must persist and the unflushed third must be lost")
        XCTAssertFalse(questionCounter.exists, "unexpected session resume state")
    }

    func test_D_9() {
        launch(.demoData)
        startSessionFromToday("D-9")
        let total = sessionPosition()?.total ?? 0
        let outcomes = finishQuiz("D-9", capture: false)
        note("D-9", "outcomes (option A each): \(outcomes) of \(total)")
        Thread.sleep(forTimeInterval: 2.5)
        shot("D-9", "1-complete")
        dump("D-9", "1-complete")
        XCTAssertTrue(text(containing: "Session complete").exists, "no Session complete line")
        for label in ["day streak", "CARDS", "CORRECT", "ACCURACY"] {
            XCTAssertTrue(text(containing: label).exists, "missing \(label)")
        }
        XCTAssertEqual(text(containing: "NEEDS REINFORCEMENT").exists, outcomes.contains(false), "NEEDS REINFORCEMENT presence wrong")
        let cards = app.staticTexts.matching(NSPredicate(format: "label == %@", "\(total)")).count
        note("D-9", "staticTexts equal to \(total): \(cards); streak: \(text(containing: "day streak").label)")
        note("D-9", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(app.buttons["One more session"].exists, "One more session offered although nothing is due")
        let done = app.buttons["Done"]
        note("D-9", "Done exists \(done.exists) hittable-at-rest \(done.isHittable)")
        XCTAssertTrue(done.exists && done.isHittable, "pinned Done not hittable at rest")
        XCTAssertFalse(app.tabBars.firstMatch.exists && app.tabBars.firstMatch.isHittable, "tab bar visible on Session Complete")
    }

    func test_D_10() {
        launch(.demoData)
        goToToday()
        startSessionFromToday("D-10")
        _ = finishQuiz("D-10", capture: false)
        Thread.sleep(forTimeInterval: 2)
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 4) && done.isHittable, "pinned Done not hittable at rest")
        XCTAssertFalse(app.buttons["One more session"].exists, "One more session offered although nothing is due")
        done.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("D-10", "1-after-done")
        dump("D-10", "1-after-done")
        XCTAssertTrue(app.staticTexts["All caught up"].waitForExistence(timeout: 4), "Today does not show All caught up: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(questionCounter.exists, "still in a session after Done")
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 4), "tab bar not back on Today")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
    }

    func test_D_11() {
        launch(.demoData)
        let initial = todayCardCount() ?? -1
        startSessionFromToday("D-11")
        // 1. Leave with zero answers.
        backButton.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("D-11", "1-left-immediately")
        note("D-11", "left with zero answers; confirmation dialog shown: \(app.alerts.count + app.sheets.count)")
        goToToday()
        XCTAssertEqual(todayCardCount(), initial, "count changed after leaving without answering")
        // 2. Answer two (one wrong if possible), leave on the reveal screen.
        startSessionFromToday("D-11")
        let first = answer(option: 0, "D-11")
        advance("D-11")
        let second = answer(option: 0, "D-11")
        note("D-11", "answered 2: \(first), \(second); leaving on the reveal screen")
        backButton.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("D-11", "2-left-mid-session")
        dump("D-11", "2-left-mid-session")
        note("D-11", "confirmation shown: \(app.alerts.count + app.sheets.count)")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        goToToday()
        Thread.sleep(forTimeInterval: 1)
        shot("D-11", "3-today-after")
        let after = todayCardCount()
        note("D-11", "initial \(initial), after leaving with 2 answered: \(String(describing: after)); streak link: \(text(containing: "day streak").exists ? text(containing: "day streak").label : "none")")
        XCTAssertEqual(after, initial - 2, "Today's count not consistent with 2 answered cards")
        // 3. A restarted session must agree with Today.
        if after ?? 0 > 0 {
            startSessionFromToday("D-11")
            XCTAssertEqual(sessionPosition()?.total, after, "new session length differs from Today's count")
            backButton.tap()
        }
        app.tapTab("Library")
        Thread.sleep(forTimeInterval: 1)
        note("D-11", "Library tiles: \(libraryTileButtons.allElementsBoundByIndex.map(\.label))")
        shot("D-11", "4-library")
        goToToday()
        Thread.sleep(forTimeInterval: 1)
        shot("D-11", "5-today-after-tab-roundtrip")
        let streakAfterTabs = text(containing: "day streak").exists
        note("D-11", "streak link after Library->Today round trip: \(streakAfterTabs)")
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        let streakAfterRelaunch = text(containing: "day streak").exists
        note("D-11", "streak link after relaunch: \(streakAfterRelaunch)")
        shot("D-11", "6-today-after-relaunch")
        XCTAssertTrue(streakAfterRelaunch, "partial session never credited a streak even after relaunch")
    }

    // MARK: E. Library, set detail, streaks, settings, paywall, consent

    /// The switch element spans the whole row; its centre is the label, which does not toggle.
    private func flip(_ toggle: XCUIElement) {
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
    }

    private func clearSearch() {
        let field = app.textFields["Search sets"]
        guard let value = field.value as? String, !value.isEmpty, value != "Search sets" else { return }
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
    }

    /// Seed: sessions.
    func test_E_1() {
        launch(.onboardedEmpty)
        openLibrary()
        shot("E-1", "1-library")
        dump("E-1", "1-library")
        let tiles = libraryTileButtons.allElementsBoundByIndex.map(\.label)
        note("E-1", "tiles: \(tiles)")
        XCTAssertGreaterThan(tiles.count, 0, "no set tiles")
        XCTAssertTrue(tiles.allSatisfy { $0.contains("% complete") || $0.contains("Mastered") }, "tile lacks mastery: \(tiles)")
        note("E-1", "due badge on any tile (sessions seed has no due cards, so none expected): \(tiles.contains { $0.contains(" due") })")
        for chip in ["All", "Due", "In progress", "Mastered"] {
            let button = app.buttons[chip]
            XCTAssertTrue(button.exists, "chip \(chip) missing")
            button.tap()
            Thread.sleep(forTimeInterval: 0.9)
            note("E-1", "chip \(chip): selected=\(button.isSelected) tiles=\(libraryTileButtons.count) emptyText=\(app.staticTexts["No sets match this filter."].exists)")
            shot("E-1", "2-chip-\(chip.replacingOccurrences(of: " ", with: "-"))")
        }
        app.buttons["All"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        let search = app.textFields["Search sets"]
        XCTAssertTrue(search.exists, "no search field")
        search.tap()
        search.typeText("photo")
        Thread.sleep(forTimeInterval: 1)
        note("E-1", "search 'photo': tiles=\(libraryTileButtons.count)")
        shot("E-1", "3-search-photo")
        XCTAssertGreaterThan(libraryTileButtons.count, 0, "search 'photo' lost the Photosynthesis set")
        app.swipeDown()
        XCTAssertTrue(app.lifecycleCheckpoint("E-1", in: self, rotate: true), "LC failed on Library with a search")
        shot("E-1", "4-after-LC")
        note("E-1", "search text after LC: \(String(describing: app.textFields["Search sets"].value))")
        XCTAssertEqual(app.textFields["Search sets"].value as? String, "photo", "search text lost over LC")
    }

    func test_E_2() {
        launch(.onboardedEmpty)
        openLibrary()
        let search = app.textFields["Search sets"]
        search.tap()
        search.typeText("zzqqxx")
        Thread.sleep(forTimeInterval: 1.2)
        shot("E-2", "1-nonsense")
        dump("E-2", "1-nonsense")
        note("E-2", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank on empty search")
        XCTAssertEqual(libraryTileButtons.count, 0)
        let empty = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'No sets' OR label CONTAINS[c] 'No results' OR label CONTAINS[c] 'no match'")).firstMatch
        XCTAssertTrue(empty.exists, "no empty-result message for a nonsense search")
        note("E-2", "empty message: \(empty.label)")
        XCTAssertFalse(empty.label.contains("filter"), "search miss reads as a filter message: '\(empty.label)'")
    }

    func test_E_3() {
        launch(.onboardedEmpty)
        openLibrary()
        let tile = libraryTileButtons.firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        let title = tile.label.components(separatedBy: ",").first ?? ""
        tile.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-3", "1-detail")
        dump("E-3", "1-detail")
        XCTAssertTrue(app.navigationBars[title].exists || app.staticTexts[title].exists, "nav title '\(title)' missing")
        XCTAssertTrue(app.buttons["Study"].exists, "no Study button")
        let sources = labelsMatching("label BEGINSWITH 'Source, '")
        note("E-3", "title \(title); source labels: \(sources.count) \(Array(sources.prefix(3))); labels: \(app.labelSnapshot().sorted())")
        XCTAssertGreaterThan(sources.count, 0, "no per-card sources shown")
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        shot("E-3", "2-detail-scrolled")
        app.swipeDown()
        app.buttons["Study"].tap()
        XCTAssertTrue(questionCounter.waitForExistence(timeout: 6), "Study did not open a quiz")
        note("E-3", "Study opens session: \(questionCounter.label)")
        shot("E-3", "3-study")
        backButton.tap()
        Thread.sleep(forTimeInterval: 1.2)
        XCTAssertTrue(app.buttons["Study"].waitForExistence(timeout: 4), "back from quiz did not return to detail")
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertGreaterThan(libraryTileButtons.count, 0, "Library tiles missing after back")
    }

    /// Seed: userSet (a non-sample set; no demo reseeding).
    func test_E_4() {
        launch(.onboardedEmpty)
        goToToday()
        let todayBefore = app.labelSnapshot()
        shot("E-4", "0-today-before")
        openLibrary()
        let tile = libraryTileButtons.firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "no tile")
        let title = tile.label.components(separatedBy: ",").first ?? ""
        tile.press(forDuration: 1.2)
        Thread.sleep(forTimeInterval: 1)
        shot("E-4", "1-context-menu")
        let menuDelete = app.buttons["Delete"]
        XCTAssertTrue(menuDelete.waitForExistence(timeout: 4), "no Delete in the context menu")
        menuDelete.tap()
        let alert = app.alerts["Delete Set"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4), "no confirmation alert")
        shot("E-4", "2-confirm")
        note("E-4", "alert labels: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertGreaterThan(libraryTileButtons.count, 0, "Cancel removed the set")
        libraryTileButtons.firstMatch.press(forDuration: 1.2)
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.alerts["Delete Set"].waitForExistence(timeout: 4))
        app.alerts["Delete Set"].buttons["Delete"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-4", "3-after-delete")
        dump("E-4", "3-after-delete")
        XCTAssertEqual(libraryTileButtons.count, 0, "tile still present after delete")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank after delete")
        goToToday()
        Thread.sleep(forTimeInterval: 1)
        shot("E-4", "4-today-after")
        note("E-4", "deleted '\(title)'. Today labels after: \(app.labelSnapshot().sorted()); before had \(todayBefore.sorted())")
        XCTAssertFalse(app.buttons["Start Session"].exists, "Today still offers a session")
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        shot("E-4", "5-relaunch-today")
        XCTAssertFalse(app.buttons["Start Session"].exists, "set came back after relaunch (Today)")
        openLibrary()
        shot("E-4", "6-relaunch-library")
        XCTAssertEqual(libraryTileButtons.count, 0, "set came back after relaunch (Library)")
    }

    /// Seed: sessions (sample set with demo mode on). Deleting the sample while the toggle stays on.
    func test_E_4b() {
        launch(.onboardedEmpty)
        openLibrary()
        let tile = libraryTileButtons.firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5))
        tile.press(forDuration: 1.2)
        app.buttons["Delete"].tap()
        app.alerts["Delete Set"].buttons["Delete"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertEqual(libraryTileButtons.count, 0)
        shot("E-4b", "1-deleted")
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("E-4b", "2-after-relaunch")
        note("E-4b", "tiles after relaunch: \(libraryTileButtons.allElementsBoundByIndex.map(\.label))")
        XCTAssertEqual(libraryTileButtons.count, 0, "deleted sample set came back on relaunch while Show Sample Set is on")
    }

    /// Seed: userSet. allowanceSpent forces the ADD CARDS section.
    func test_E_5() {
        launch(.allowanceSpent)
        openLibrary()
        Thread.sleep(forTimeInterval: 1)
        shot("E-5", "1-library")
        dump("E-5", "1-library")
        let before = libraryTileButtons.count
        XCTAssertTrue(app.staticTexts["ADD CARDS"].exists, "no ADD CARDS section")
        XCTAssertFalse(app.buttons["Study"].exists)
        // Is there any way to add cards to the existing set? Check the detail screen.
        libraryTileButtons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.2)
        shot("E-5", "2-detail")
        let detailAdd = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'add' OR label CONTAINS[c] 'import'")).count
        note("E-5", "add/import controls on set detail: \(detailAdd); toolbar buttons: \(app.navigationBars.buttons.allElementsBoundByIndex.map(\.label))")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons.matching(NSPredicate(format: "label CONTAINS 'Type cards'")).firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Type cards"].waitForExistence(timeout: 5), "Type cards sheet missing")
        shot("E-5", "3-type-cards")
        dump("E-5", "3-type-cards")
        note("E-5", "sheet labels: \(app.labelSnapshot().sorted())")
        let title = app.textFields["Set title"]
        XCTAssertTrue(title.exists)
        title.tap()
        title.typeText("E2E typed set")
        for (index, pair) in [("Term A", "Definition A"), ("Term B", "Definition B")].enumerated() {
            let term = app.textFields["Card \(index + 1) term"]
            if !term.exists { app.buttons["Add another card"].tap() }
            term.tap()
            term.typeText(pair.0)
            let definition = app.textFields["Card \(index + 1) definition"].exists ? app.textFields["Card \(index + 1) definition"] : app.textViews["Card \(index + 1) definition"]
            definition.tap()
            definition.typeText(pair.1)
        }
        shot("E-5", "4-filled")
        let save = app.navigationBars["Type cards"].buttons.matching(NSPredicate(format: "label BEGINSWITH 'Save'")).firstMatch
        XCTAssertTrue(save.exists, "no Save in Type cards")
        note("E-5", "save label: \(save.label)")
        save.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-5", "5-after-save")
        note("E-5", "tiles before \(before) after \(libraryTileButtons.count): \(libraryTileButtons.allElementsBoundByIndex.map(\.label))")
        XCTAssertEqual(libraryTileButtons.count, before, "ADD CARDS appends to the existing set (expected: tile count unchanged); it created \(libraryTileButtons.count - before) new set(s) instead")
    }

    func test_E_6() {
        launch(.onboardedEmpty)
        goToToday()
        let link = text(containing: "day streak")
        XCTAssertTrue(link.waitForExistence(timeout: 5), "no streak link on Today (sessions seed has today's session)")
        link.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-6", "1-streak")
        dump("E-6", "1-streak")
        let labels = app.labelSnapshot().sorted()
        note("E-6", "labels: \(labels)")
        XCTAssertTrue(app.navigationBars["Streak"].exists)
        XCTAssertTrue(app.element(labelled: "This week").exists, "no week strip")
        XCTAssertTrue(text(containing: "Longest").exists, "no longest-streak comparison")
        XCTAssertTrue(text(containing: "Streak Freeze").exists, "no freeze row")
        XCTAssertTrue(text(containing: "Earn one per full study week").exists)
        let promises = labels.filter { $0.localizedCaseInsensitiveContains("notif") || $0.localizedCaseInsensitiveContains("remind") }
        XCTAssertTrue(promises.isEmpty, "copy promises notifications: \(promises)")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(text(containing: "day streak").exists, "did not return to Today")
    }

    func test_E_7() {
        launch(.onboardedEmpty)
        app.tapTab("Stats")
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-7", "1-stats-data")
        dump("E-7", "1-stats-data")
        note("E-7", "data labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(text(containing: "OVERALL PROGRESS").exists, "stats with data: no OVERALL PROGRESS")
        XCTAssertTrue(text(containing: "BY SET").exists)
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        app.swipeUp()
        shot("E-7", "2-stats-data-scrolled")
        // No data: a fresh install with only the onboarding flags.
        app.terminate()
        app = QSApp.launch(.freshInstall, .onboardedEmpty)
        app.tapTab("Stats")
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-7", "3-stats-empty")
        dump("E-7", "3-stats-empty")
        XCTAssertTrue(text(containing: "No stats yet").exists, "no empty state: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
    }

    func test_E_8() {
        launch(.onboardedEmpty)
        openSettings("E-8")
        shot("E-8", "1-settings")
        dump("E-8", "1-settings")
        note("E-8", "labels: \(app.labelSnapshot().sorted())")
        for row in ["Handwriting Mode", "Spell Check", "Show Sample Set", "Share anonymous usage"] {
            let toggle = app.switches[row]
            XCTAssertTrue(toggle.exists, "no switch \(row)")
        }
        // Handwriting and Spell Check flip and persist across a relaunch.
        for row in ["Handwriting Mode", "Spell Check", "Share anonymous usage"] {
            let toggle = app.switches[row]
            let before = toggle.value as? String
            flip(toggle)
            Thread.sleep(forTimeInterval: 0.6)
            let after = toggle.value as? String
            note("E-8", "\(row): \(String(describing: before)) -> \(String(describing: after))")
            XCTAssertNotEqual(before, after, "\(row) did not flip")
            flip(toggle)
            Thread.sleep(forTimeInterval: 0.6)
            XCTAssertEqual(toggle.value as? String, before, "\(row) did not flip back")
        }
        // AI source: External API needs a confirmation, then shows the key fields.
        let source = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'AI Source'")).firstMatch
        XCTAssertTrue(source.exists, "no AI Source picker")
        note("E-8", "AI Source label: \(source.label)")
        source.tap()
        Thread.sleep(forTimeInterval: 0.8)
        shot("E-8", "2-ai-source-menu")
        app.buttons["External API"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        shot("E-8", "3-confirm-external")
        let confirm = app.buttons["Use External API"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 4), "no confirmation before switching to External API")
        confirm.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("E-8", "4-external-fields")
        dump("E-8", "4-external-fields")
        let keyField = app.secureTextFields["API Key"]
        XCTAssertTrue(keyField.waitForExistence(timeout: 4), "no secure API Key field")
        keyField.tap()
        keyField.typeText("sk-test-e2e-fake")
        let endpoint = app.textFields["Endpoint URL"]
        endpoint.tap()
        Thread.sleep(forTimeInterval: 0.8)
        note("E-8", "key field value after typing: \(String(describing: keyField.value)); typed key visible in any label: \(app.labelSnapshot().contains { $0.contains("sk-test") })")
        shot("E-8", "5-key-entered")
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'sk-test' OR value CONTAINS 'sk-test'")).count > 0, "API key shown in plain text")
        // Close Settings and reopen: key persisted and still masked.
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.2)
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        let reopened = app.secureTextFields["API Key"]
        XCTAssertTrue(reopened.waitForExistence(timeout: 4))
        note("E-8", "reopened key value: \(String(describing: reopened.value))")
        shot("E-8", "6-reopened")
        XCTAssertFalse((reopened.value as? String ?? "").contains("sk-test"), "key readable after saving")
        XCTAssertFalse((reopened.value as? String ?? "").isEmpty || (reopened.value as? String) == "API Key", "key not persisted after reopening")
        // Relaunch: persisted in the Keychain.
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openSettings("E-8")
        let afterLaunch = app.secureTextFields["API Key"]
        note("E-8", "after relaunch key value: \(String(describing: afterLaunch.value)), exists \(afterLaunch.exists)")
        shot("E-8", "7-after-relaunch")
        XCTAssertTrue(afterLaunch.waitForExistence(timeout: 4), "AI source did not persist")
        // Remove the fake key and restore On-Device.
        afterLaunch.tap()
        let current = (afterLaunch.value as? String) ?? ""
        afterLaunch.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: max(current.count, 20)))
        app.textFields["Endpoint URL"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        note("E-8", "key value after clear: \(String(describing: app.secureTextFields["API Key"].value))")
        shot("E-8", "8-key-cleared")
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'AI Source'")).firstMatch.tap()
        app.buttons["On-Device"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        XCTAssertFalse(app.secureTextFields["API Key"].exists, "key field still visible in On-Device mode")
        // Pro row.
        XCTAssertTrue(app.buttons["Upgrade to QuickStudy Pro"].exists, "no upgrade row")
        // About.
        note("E-8", "version row: \(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Version'")).allElementsBoundByIndex.map(\.label)) privacy link exists: \(app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists)")
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.6)
        shot("E-8", "9-bottom")
        XCTAssertTrue(app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists, "no Privacy Policy link")
    }

    /// Seed: sessions (Show Sample Set persisted on, so the app can flip it).
    func test_E_8_sample() {
        launch(.onboardedEmpty)
        openLibrary()
        XCTAssertEqual(libraryTileButtons.count, 1, "sample set not present at start")
        note("E-8s", "tile at start: \(libraryTileButtons.firstMatch.label)")
        openSettings("E-8s")
        let toggle = app.switches["Show Sample Set"]
        note("E-8s", "toggle initial: \(String(describing: toggle.value))")
        XCTAssertEqual(toggle.value as? String, "1")
        shot("E-8s", "0-settings")
        flip(toggle)
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-8s", "0b-after-flip")
        note("E-8s", "AX value 1.5s after flip (screenshot shows it off): \(String(describing: toggle.value)); re-queried: \(String(describing: app.switches["Show Sample Set"].value))")
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-8s", "1-off-today")
        goToToday()
        XCTAssertTrue(app.staticTexts["Build your first set"].waitForExistence(timeout: 4), "Today not empty after the sample was turned off: \(app.labelSnapshot().sorted())")
        openLibrary()
        shot("E-8s", "2-off-library")
        XCTAssertEqual(libraryTileButtons.count, 0, "sample tile still in Library")
        openSettings("E-8s")
        flip(app.switches["Show Sample Set"])
        Thread.sleep(forTimeInterval: 1)
        dismissSheet()
        Thread.sleep(forTimeInterval: 1.5)
        goToToday()
        shot("E-8s", "3-on-today")
        XCTAssertFalse(app.staticTexts["Build your first set"].exists, "sample not back on Today")
        note("E-8s", "today count after re-enabling: \(String(describing: todayCardCount()))")
        openLibrary()
        shot("E-8s", "4-on-library")
        XCTAssertGreaterThan(libraryTileButtons.count, 0, "sample not back in Library")
        note("E-8s", "tiles: \(libraryTileButtons.allElementsBoundByIndex.map(\.label))")
        // Delete All Study Sets.
        openSettings("E-8s")
        app.swipeUp()
        app.buttons["Delete All Study Sets"].tap()
        let alert = app.alerts["Delete All Data"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4), "no delete-all confirmation")
        shot("E-8s", "5-delete-all-alert")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        dismissSheet()
        openLibrary()
        XCTAssertGreaterThan(libraryTileButtons.count, 0, "Cancel deleted data")
        openSettings("E-8s")
        app.swipeUp()
        app.buttons["Delete All Study Sets"].tap()
        app.alerts["Delete All Data"].buttons["Delete Everything"].tap()
        Thread.sleep(forTimeInterval: 1.2)
        dismissSheet()
        openLibrary()
        shot("E-8s", "6-after-delete-all")
        XCTAssertEqual(libraryTileButtons.count, 0, "sets remain after Delete Everything")
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("E-8s", "7-delete-all-relaunch")
        note("E-8s", "tiles after relaunch following Delete Everything: \(libraryTileButtons.allElementsBoundByIndex.map(\.label))")
        XCTAssertEqual(libraryTileButtons.count, 0, "Delete Everything undone by relaunch (sample reseeded)")
    }

    func test_E_9() {
        launch(.onboardedEmpty)
        goToToday()
        let pill = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'free generations left'")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 5), "no generations pill: \(app.labelSnapshot().sorted())")
        note("E-9", "pill: \(pill.label) hint: \(pill.value ?? "")")
        shot("E-9", "0-pill")
        pill.tap()
        Thread.sleep(forTimeInterval: 3)
        shot("E-9", "1-paywall")
        dump("E-9", "1-paywall")
        note("E-9", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(text(containing: "QuickStudy Pro").exists, "no paywall header")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Monthly'")).count > 0
                      || text(containing: "Monthly").exists, "monthly product missing/not loaded")
        XCTAssertTrue(text(containing: "Yearly").exists || app.buttons.matching(NSPredicate(format: "label CONTAINS 'Yearly'")).count > 0, "yearly product missing")
        XCTAssertTrue(app.buttons["Restore Subscription"].exists || app.buttons["Restore Purchases"].exists, "no restore")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.8)
        shot("E-9", "2-paywall-scrolled")
        note("E-9", "labels scrolled: \(app.labelSnapshot().sorted())")
    }

    func test_E_10() throws {
        try StoreKitTesting.startSession()
        launch(.onboardedEmpty)
        goToToday()
        let pill = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'free generations left'")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 5))
        pill.tap()
        Thread.sleep(forTimeInterval: 3)
        shot("E-10", "1-paywall")
        let monthly = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Monthly'")).firstMatch
        if monthly.exists { monthly.tap(); Thread.sleep(forTimeInterval: 0.8) }
        shot("E-10", "2-monthly-selected")
        let action = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Accept Offer' OR label BEGINSWITH 'Subscribe' OR label BEGINSWITH 'Try' OR label BEGINSWITH 'Start'")).firstMatch
        XCTAssertTrue(action.waitForExistence(timeout: 4), "no purchase button: \(app.labelSnapshot().sorted())")
        note("E-10", "purchase button: \(action.label)")
        action.tap()
        Thread.sleep(forTimeInterval: 3)
        shot("E-10", "3-after-tap")
        dump("E-10", "3-after-tap")
        let welcome = app.alerts["You\u{2019}re on QuickStudy Pro"].exists ? app.alerts["You\u{2019}re on QuickStudy Pro"] : app.alerts["You're on QuickStudy Pro"]
        if !welcome.waitForExistence(timeout: 12) {
            let system = SystemAlerts.springboard
            note("E-10", "no welcome alert; springboard alerts: \(system.alerts.count) labels \(app.labelSnapshot().sorted()) alerts: \(app.alerts.allElementsBoundByIndex.map(\.label))")
            shot("E-10", "3b-no-welcome")
            XCTFail("purchase did not complete through the paywall UI")
            return
        }
        note("E-10", "welcome alert: \(welcome.label); \(welcome.staticTexts.allElementsBoundByIndex.map(\.label))")
        shot("E-10", "4-welcome")
        welcome.buttons["Continue"].tap()
        Thread.sleep(forTimeInterval: 2)
        shot("E-10", "5-after-continue")
        goToToday()
        let proPill = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'QuickStudy Pro'")).firstMatch
        XCTAssertTrue(proPill.waitForExistence(timeout: 6), "pill did not turn Pro: \(app.labelSnapshot().sorted())")
        note("E-10", "pill: \(proPill.label)")
        shot("E-10", "6-pro-pill")
        XCTAssertTrue(proPill.label.contains("150 of 150"), "hosted count wrong: \(proPill.label)")
        openSettings("E-10")
        note("E-10", "settings pro rows: \(app.labelSnapshot().sorted())")
        shot("E-10", "7-settings-pro")
        XCTAssertTrue(text(containing: "Active").exists || app.staticTexts["Active"].exists, "Settings does not show Pro active")
    }

    func test_E_11() throws {
        try StoreKitTesting.startSession()
        launch(.onboardedEmpty)
        openSettings("E-11")
        app.buttons["Upgrade to QuickStudy Pro"].tap()
        Thread.sleep(forTimeInterval: 3)
        let restore = app.buttons["Restore Subscription"].exists ? app.buttons["Restore Subscription"] : app.buttons["Restore Purchases"]
        XCTAssertTrue(restore.waitForExistence(timeout: 6), "no restore button")
        // 1. Nothing to restore.
        restore.tap()
        Thread.sleep(forTimeInterval: 4)
        shot("E-11", "1-restore-nothing")
        dump("E-11", "1-restore-nothing")
        note("E-11", "after restore (no purchase): alerts \(app.alerts.allElementsBoundByIndex.map(\.label)) springboard alerts \(SystemAlerts.springboard.alerts.count); restore enabled \(restore.isEnabled) exists \(restore.exists)")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "blank after restore")
        // 2. A purchase appears on the account while the paywall is open, then Restore.
        try StoreKitTesting.purchase(.monthly)
        Thread.sleep(forTimeInterval: 1)
        if app.alerts.count > 0 { app.alerts.firstMatch.buttons.firstMatch.tap(); Thread.sleep(forTimeInterval: 1) }
        let restore2 = app.buttons["Restore Subscription"].exists ? app.buttons["Restore Subscription"] : app.buttons["Restore Purchases"]
        if restore2.exists {
            restore2.tap()
            Thread.sleep(forTimeInterval: 5)
        }
        shot("E-11", "2-restore-after-purchase")
        dump("E-11", "2-restore-after-purchase")
        note("E-11", "after restore: labels \(app.labelSnapshot().sorted()); alerts \(app.alerts.allElementsBoundByIndex.map(\.label))")
        XCTAssertEqual(app.state, .runningForeground)
        // Close the paywall and Settings; entitlement should be refreshed on dismissal.
        let close = app.buttons["Close"].exists ? app.buttons["Close"] : app.buttons["X"]
        if close.exists { close.tap() } else { dismissSheet() }
        Thread.sleep(forTimeInterval: 2)
        shot("E-11", "3-after-close")
        note("E-11", "settings after close: labels \(app.labelSnapshot().sorted())")
        let proRow = text(containing: "Active").exists || app.buttons["Manage Subscription"].exists
        XCTAssertTrue(proRow, "restore did not move the app to Pro (Settings still shows Upgrade)")
    }

    func test_E_12() {
        launch(.onboardedEmpty)
        openSettings("E-12")
        shot("E-12", "1-settings-top")
        var labels = app.labelSnapshot()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.6)
        labels.formUnion(app.labelSnapshot())
        shot("E-12", "2-settings-bottom")
        let consent = labels.filter { $0.localizedCaseInsensitiveContains("consent") || $0.localizedCaseInsensitiveContains("Private Cloud") || $0.localizedCaseInsensitiveContains("Cloud drafting") || $0.localizedCaseInsensitiveContains("revoke") }
        note("E-12", "consent-related labels in Settings: \(consent)")
        note("E-12", "all settings labels: \(labels.sorted())")
        XCTAssertFalse(consent.isEmpty, "Settings exposes no hosted-consent control (grant/revoke)")
    }

    func test_E_13() {
        launch(.onboardedEmpty)
        openSettings("E-13")
        app.swipeUp()
        app.buttons["What's New"].tap()
        Thread.sleep(forTimeInterval: 2.5)
        shot("E-13", "1-whats-new")
        dump("E-13", "1-whats-new")
        note("E-13", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(text(containing: "VERSION").exists, "no version label")
        XCTAssertTrue(app.staticTexts["What's New"].exists || text(containing: "What's New").exists)
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        let proButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'QuickStudy Pro'")).firstMatch
        note("E-13", "pro card present: \(proButton.exists)")
        app.buttons["Continue"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-13", "2-dismissed")
        XCTAssertTrue(app.navigationBars["Settings"].exists, "did not return to Settings")
        XCTAssertFalse(app.buttons["Continue"].exists, "What's New still up")
        // Version bump route: launch with an older last-seen release.
        app.terminate()
        app = QSApp.launch(states: [], extraArguments: ["-qs_hasCompletedOnboarding", "YES", "-qs_lastSeenRelease", "1"])
        Thread.sleep(forTimeInterval: 4)
        shot("E-13", "3-bump")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 6), "What's New not shown after a release bump")
        app.buttons["Continue"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("E-13", "4-bump-dismissed")
        XCTAssertFalse(app.buttons["Continue"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists || app.buttons["Start Session"].exists, "Today not shown after dismissing")
    }
}

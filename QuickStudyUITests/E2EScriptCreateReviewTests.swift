import XCTest

/// Sections B (Create) and C (Review drafts) of audit/e2e-test-script.md. One method per step ID.
/// Seed first: `Scripts/seed.sh <udid> onboardedEmpty` for B, `midDraft` for C.
final class E2EScriptCreateReviewTests: QSTestCase {
    private let shortNote = "Mitochondria are organelles that produce most of a cell's ATP through cellular respiration. They have a double membrane, and the folded inner membrane, called cristae, increases surface area. Mitochondria contain their own DNA, inherited from the mother."

    // MARK: Shared

    @discardableResult
    private func finishGeneration(_ id: String, timeout: TimeInterval = QSApp.generationTimeout) -> GenerationOutcome {
        let (outcome, seconds) = awaitGenerationOutcome(id, timeout: timeout)
        note(id, "outcome: \(outcome) after \(String(format: "%.1f", seconds)) s")
        shot(id, "outcome")
        dump(id, "outcome")
        return outcome
    }

    private func assertReachedDrafts(_ id: String, _ outcome: GenerationOutcome) {
        switch outcome {
        case .scanPreview:
            note(id, "scan preview labels: \(app.labelSnapshot().sorted())")
            continueToReviewDrafts(id)
        case .reviewDrafts:
            break
        case let .failure(title):
            XCTFail("\(id): generation failed with '\(title)'. Labels: \(app.labelSnapshot().sorted())")
        case .timedOut:
            XCTFail("\(id): no result within the timeout")
        }
        shot(id, "review-drafts")
        dump(id, "review-drafts")
        let save = button(beginningWith: "Save ")
        if save.exists { note(id, "CTA: \(save.label)") }
        note(id, "review labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "\(id): blank on Review drafts")
    }

    private func openPasteSheet(_ id: String) {
        chooseSource(id, label: "Text, Paste")
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: QSApp.uiTimeout), "\(id): paste sheet did not open. Labels: \(app.labelSnapshot().sorted())")
    }

    private func tapGenerate(_ id: String) {
        dismissKeyboardOnSheet()
        let generate = app.buttons["Generate cards"]
        XCTAssertTrue(generate.waitForExistence(timeout: 5), "\(id): no Generate cards")
        XCTAssertTrue(generate.isEnabled, "\(id): Generate cards disabled")
        generate.tap()
    }

    // MARK: B

    func test_B_1() {
        launch(.onboardedEmpty)
        openNewSetSheet("B-1")
        shot("B-1", "sheet")
        dump("B-1", "sheet")
        note("B-1", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.buttons["Scan with camera, Fastest, recommended"].exists, "No primary scan row")
        XCTAssertTrue(app.staticTexts["Scan with camera"].exists, "Primary row title missing")
        XCTAssertTrue(app.staticTexts["Fastest · recommended"].exists, "Primary row subtitle missing")
        for tile in ["Photo", "PDF", "Text"] {
            XCTAssertTrue(app.staticTexts[tile].exists, "Tile \(tile) missing")
        }
        for sub in ["Library", "Files", "Paste"] {
            XCTAssertTrue(app.staticTexts[sub].exists, "Tile subtitle \(sub) missing")
        }
        app.lifecycleCheckpoint("B-1", in: self, rotate: true)
        shot("B-1", "after-lc")
        XCTAssertTrue(app.staticTexts["Capture a page and cards draft automatically."].exists, "Sheet gone after LC")
    }

    func test_B_2() {
        launch(.onboardedEmpty)
        chooseSource("B-2", label: "Scan with camera, Fastest, recommended")
        Thread.sleep(forTimeInterval: 2)
        shot("B-2", "after-scan-tap")
        dump("B-2", "after-scan-tap")
        let alert = app.alerts["Camera Unavailable"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5), "No Camera Unavailable alert. Labels: \(app.labelSnapshot().sorted())")
        note("B-2", "alert: \(alert.label) / \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        XCTAssertEqual(app.state, .runningForeground)
        alert.buttons["OK"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after dismissing alert")
        shot("B-2", "after-ok")
    }

    func test_B_3() {
        launch(.onboardedEmpty)
        chooseSource("B-3", label: "Photo, Library")
        pickFirstPhoto("B-3")
        let outcome = finishGeneration("B-3")
        assertReachedDrafts("B-3", outcome)
    }

    func test_B_4() {
        launch(.onboardedEmpty)
        chooseSource("B-4", label: "PDF, Files")
        pickFile("B-4", named: "small.pdf")
        let sawGenerating = waitForGenerating(timeout: 20)
        shot("B-4", "generating-first")
        dump("B-4", "generating-first")
        note("B-4", "generating visible: \(sawGenerating); labels: \(app.labelSnapshot().sorted())")
        if sawGenerating { softLifecycle("B-4", name: "after-lc-generating") }
        let outcome = finishGeneration("B-4")
        assertReachedDrafts("B-4", outcome)
        let pills = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'p.'")).count
        note("B-4", "p. pills visible: \(pills)")
    }

    func test_B_5() {
        launch(.onboardedEmpty)
        openPasteSheet("B-5")
        let editor = app.textViews.firstMatch
        let text = fixtureText("notes.txt")
        XCTAssertFalse(text.isEmpty, "notes.txt fixture unreadable")
        UIPasteboard.general.string = text
        editor.tap()
        editor.press(forDuration: 1.2)
        let paste = app.menuItems["Paste"].exists ? app.menuItems["Paste"] : app.buttons["Paste"]
        var pasted = false
        if paste.waitForExistence(timeout: 3) {
            paste.tap()
            SystemAlerts.handle(.allow, timeout: 4)
            Thread.sleep(forTimeInterval: 1.5)
            pasted = ((editor.value as? String)?.count ?? 0) > 200
        }
        note("B-5", "pasted via pasteboard: \(pasted)")
        if !pasted {
            shot("B-5", "paste-menu-failed")
            editor.tap()
            editor.typeText(text)
        }
        shot("B-5", "pasted")
        dump("B-5", "pasted")
        note("B-5", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label MATCHES '[0-9]+ words'")).firstMatch.exists, "No word count")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '~'")).firstMatch.exists, "No predicted card chip")
        XCTAssertTrue(app.staticTexts["10 of 10 free left"].exists, "No allowance counter")
        XCTAssertTrue(app.staticTexts["On this iPhone · no upload · works offline"].exists, "No footer promise")
        note("B-5", "has 'pasted from' source line: \(self.text(containing: "pasted from").exists); has 'Definitions' chip: \(self.text(containing: "Definitions").exists)")
        tapGenerate("B-5")
        let outcome = finishGeneration("B-5")
        assertReachedDrafts("B-5", outcome)
    }

    func test_B_6() {
        launch(.onboardedEmpty)
        openPasteSheet("B-6")
        typeIntoPasteSheet("B-6", text: fixtureText("notes-short.txt").trimmingCharacters(in: .whitespacesAndNewlines))
        shot("B-6", "typed")
        tapGenerate("B-6")
        let outcome = finishGeneration("B-6")
        note("B-6", "result: \(outcome)")
        switch outcome {
        case .scanPreview, .reviewDrafts: assertReachedDrafts("B-6", outcome)
        case .failure: XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank error screen")
        case .timedOut: XCTFail("B-6: no result")
        }
    }

    func test_B_7() {
        launch(.onboardedEmpty)
        openPasteSheet("B-7")
        let generate = app.buttons["Generate cards"]
        XCTAssertTrue(generate.waitForExistence(timeout: 4))
        shot("B-7", "empty")
        note("B-7", "empty: Generate enabled=\(generate.isEnabled)")
        XCTAssertFalse(generate.isEnabled, "Generate enabled with an empty editor")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("   \n  \n   ")
        shot("B-7", "whitespace")
        note("B-7", "whitespace: Generate enabled=\(generate.isEnabled)")
        XCTAssertFalse(generate.isEnabled, "Generate enabled with whitespace only")
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(generatingVisible, "Generating appeared for whitespace")
        shot("B-7", "end")
    }

    func test_B_8() {
        launch(.onboardedEmpty)
        chooseSource("B-8", label: "PDF, Files")
        pickFile("B-8", named: "large.pdf")
        let started = Date()
        let drafting = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label MATCHES %@", "^Drafting cards · [0-9]+ of [0-9]+$")).firstMatch
        let reading = app.element(labelContaining: "Reading page")
        var sampledReading = false
        while !drafting.exists, Date().timeIntervalSince(started) < 120 {
            if reading.exists, !sampledReading {
                sampledReading = true
                shot("B-8", "reading")
                note("B-8", "reading label: \(reading.label) at \(Int(Date().timeIntervalSince(started))) s")
            }
            for title in Self.failureTitles where app.staticTexts[title].exists {
                shot("B-8", "failure")
                XCTFail("B-8: large.pdf failed with '\(title)'. Labels: \(app.labelSnapshot().sorted())")
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        guard drafting.exists else {
            shot("B-8", "TIMEOUT-120s")
            dump("B-8", "TIMEOUT-120s")
            app.terminate()
            XCTFail("B-8: no 'Drafting cards · N of M' label within 120 s (killed). Labels: \(app.labelSnapshot().sorted())")
            return
        }
        let draftingStarted = Date()
        note("B-8", "drafting label appeared after \(Int(draftingStarted.timeIntervalSince(started))) s: \(drafting.label)")
        shot("B-8", "drafting")
        dump("B-8", "drafting")
        let detail = (drafting.value as? String) ?? ""
        note("B-8", "drafting value: \(detail)")
        XCTAssertTrue(detail.contains("usually takes about"), "no honest duration estimate for 320 pages. Value: \(detail)")
        let firstLabel = drafting.label
        var lastLabel = firstLabel
        var lastChange = Date()
        var progressed = false
        while Date().timeIntervalSince(lastChange) < 90 {
            XCTAssertFalse(reading.exists, "B-8: 'Reading page' label reappeared after drafting started")
            let current = drafting.exists ? drafting.label : lastLabel
            if current != lastLabel {
                note("B-8", "progress: '\(lastLabel)' -> '\(current)' after \(Int(Date().timeIntervalSince(draftingStarted))) s")
                progressed = true
                break
            }
            Thread.sleep(forTimeInterval: 1)
            lastLabel = current
            if !drafting.exists { break }
        }
        shot("B-8", "before-cancel")
        XCTAssertTrue(progressed || !drafting.exists, "B-8: drafting label stalled at '\(firstLabel)' for 90 s")
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "B-8: no Cancel while drafting")
        cancel.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-8", "after-cancel")
        note("B-8", "labels after Cancel: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(drafting.exists, "B-8: still drafting after Cancel")
    }

    func test_B_9() {
        launch(.onboardedEmpty)
        chooseSource("B-9", label: "PDF, Files")
        pickFile("B-9", named: "corrupt.pdf")
        var sawGenerating = false
        let probeEnd = Date().addingTimeInterval(5)
        while Date() < probeEnd, !sawGenerating {
            sawGenerating = generatingVisible
            Thread.sleep(forTimeInterval: 0.1)
        }
        note("B-9", "Generating cover ever visible in 5 s: \(sawGenerating)")
        let outcome = finishGeneration("B-9", timeout: 30)
        if case .timedOut = outcome {
            XCUIDevice.shared.press(.home)
            Thread.sleep(forTimeInterval: 1)
            app.activate()
            Thread.sleep(forTimeInterval: 2)
            shot("B-9", "after-lc-still-nothing")
            openLibrary()
            app.buttons["New set"].tap()
            Thread.sleep(forTimeInterval: 2)
            shot("B-9", "after-reopening-new-set")
            note("B-9", "after reopening New set, labels: \(app.labelSnapshot().sorted())")
        }
        note("B-9", "labels: \(app.labelSnapshot().sorted())")
        guard case .failure = outcome else {
            XCTFail("B-9: expected an error screen, got \(outcome)")
            return
        }
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        XCTAssertTrue(app.buttons["Try again"].exists || app.buttons["Paste text"].exists, "No recovery buttons")
        app.lifecycleCheckpoint("B-9", in: self)
    }

    func test_B_10() {
        launch(.onboardedEmpty, .noAppleIntelligence)
        chooseSource("B-10", label: "Text, Paste", declineConsent: false)
        shot("B-10", "after-text-tap")
        dump("B-10", "after-text-tap")
        let consent = app.buttons["Not now"].waitForExistence(timeout: 4)
        note("B-10", "consent sheet shown: \(consent); labels: \(app.labelSnapshot().sorted())")
        if consent {
            app.buttons["Not now"].tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        shot("B-10", "after-decline")
        dump("B-10", "after-decline")
        note("B-10", "after decline labels: \(app.labelSnapshot().sorted())")
        if app.textViews.firstMatch.waitForExistence(timeout: 4) {
            typeIntoPasteSheet("B-10", text: shortNote)
            tapGenerate("B-10")
            let outcome = finishGeneration("B-10", timeout: 60)
            note("B-10", "outcome after generate: \(outcome)")
            guard case .failure = outcome else {
                XCTFail("B-10: expected the no-model path, got \(outcome)")
                return
            }
            XCTAssertTrue(app.buttons["Type cards by hand"].exists || app.buttons["Try again"].exists, "No recovery")
        } else {
            XCTAssertTrue(app.staticTexts["Type cards"].exists || app.navigationBars["Type cards"].exists,
                          "Neither paste sheet nor Type cards after declining: \(app.labelSnapshot().sorted())")
        }
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank end state")
    }

    func test_B_11() {
        launch(.allowanceSpent)
        openLibrary()
        shot("B-11", "library")
        dump("B-11", "library")
        note("B-11", "library labels: \(app.labelSnapshot().sorted())")
        app.buttons["New set"].tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-11", "after-new-set")
        dump("B-11", "after-new-set")
        note("B-11", "after new set labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank")
        let paywall = text(containing: "QuickStudy Pro").exists || app.buttons["Restore Subscription"].exists
            || text(containing: "Free generations used").exists
        XCTAssertTrue(paywall, "No paywall or allowance message after New set with allowance spent")
        note("B-11", "mentions allowance used: \(text(containing: "free generations").exists || text(containing: "used").exists)")
    }

    func test_B_12() {
        launch(.hostedConsentDeclined, .noAppleIntelligence)
        openLibrary()
        shot("B-12", "library")
        dump("B-12", "library")
        note("B-12", "library labels: \(app.labelSnapshot().sorted())")
        app.buttons["New set"].tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-12", "after-new-set")
        dump("B-12", "after-new-set")
        note("B-12", "after new set labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank")
        XCTAssertTrue(app.navigationBars["Type cards"].exists || app.staticTexts["Type cards"].exists
                      || app.staticTexts["Capture a page and cards draft automatically."].exists,
                      "Neither Type cards nor the New set sheet")
        XCTAssertFalse(app.buttons["Allow"].exists, "Cloud consent re-asked after decline")
    }

    func test_B_13() {
        launch(.onboardedEmpty, .noAppleIntelligence)
        chooseSource("B-13", label: "Text, Paste", declineConsent: false)
        let notNow = app.buttons["Not now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5), "B-13: consent sheet not shown. Labels: \(app.labelSnapshot().sorted())")
        shot("B-13", "consent")
        dump("B-13", "consent")
        let labels = app.labelSnapshot().sorted()
        note("B-13", "consent labels: \(labels)")
        let joined = labels.joined(separator: " ").lowercased()
        XCTAssertTrue(joined.contains("anthropic") || joined.contains("claude"), "Consent copy does not name Anthropic/Claude")
        XCTAssertTrue(joined.contains("30 days") || joined.contains("30-day"), "Consent copy does not mention 30-day deletion")
        XCTAssertFalse(joined.contains("not stored"), "Consent copy says 'not stored'")
        app.lifecycleCheckpoint("B-13", in: self)
        XCTAssertTrue(app.buttons["Allow"].exists, "Consent sheet lost after LC")
        app.buttons["Allow"].tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-13", "after-allow")
        dump("B-13", "after-allow")
        guard app.textViews.firstMatch.waitForExistence(timeout: 6) else {
            XCTFail("B-13: no paste sheet after Allow. Labels: \(app.labelSnapshot().sorted())")
            return
        }
        typeIntoPasteSheet("B-13", text: shortNote)
        note("B-13", "paste footer: \(app.labelSnapshot().filter { $0.contains("·") }.sorted())")
        tapGenerate("B-13")
        let outcome = finishGeneration("B-13", timeout: 90)
        note("B-13", "outcome after Allow: \(outcome)")
        switch outcome {
        case let .failure(title):
            note("B-13", "failure shown: \(title)")
            XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        case .scanPreview, .reviewDrafts:
            XCTFail("B-13: hosted generation unexpectedly produced a draft in the Simulator")
        case .timedOut:
            XCTFail("B-13: stuck, no failure shown within 90 s")
        }
    }

    func test_B_14() {
        launch(.onboardedEmpty)
        openPasteSheet("B-14")
        typeIntoPasteSheet("B-14", text: shortNote)
        tapGenerate("B-14")
        XCTAssertTrue(waitForGenerating(timeout: 20), "B-14: Generating never appeared")
        Thread.sleep(forTimeInterval: 3)
        shot("B-14", "generating")
        let cancel = app.buttons["Cancel"]
        XCTAssertTrue(cancel.exists, "No Cancel on Generating")
        cancel.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-14", "after-cancel")
        dump("B-14", "after-cancel")
        XCTAssertFalse(generatingVisible, "Generating still up after Cancel")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after Cancel")
        XCTAssertFalse(app.buttons["Try again"].exists, "Error screen after a user Cancel")
        Thread.sleep(forTimeInterval: 45)
        shot("B-14", "after-cancel-45s")
        XCTAssertFalse(button(beginningWith: "Review ").exists || button(beginningWith: "Save ").exists,
                       "Cancelled generation navigated to review later")
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Cancelled generation left a draft")

        openPasteSheet("B-14b")
        app.textViews.firstMatch.tap()
        let existing = (app.textViews.firstMatch.value as? String) ?? ""
        if existing.count < 50 { app.textViews.firstMatch.typeText(shortNote) }
        tapGenerate("B-14b")
        XCTAssertTrue(waitForGenerating(timeout: 20), "B-14b: Generating never appeared")
        Thread.sleep(forTimeInterval: 2)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 10)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: QSApp.uiTimeout)
        shot("B-14", "backgrounded-return")
        let outcome = finishGeneration("B-14b", timeout: 120)
        note("B-14", "after background: \(outcome)")
        XCTAssertNotEqual(outcome, .timedOut, "B-14: stuck after backgrounding")
    }

    func test_B_15() {
        launch(.hostedConsentDeclined, .noAppleIntelligence)
        openLibrary()
        app.buttons["New set"].tap()
        let title = app.textFields["Set title"]
        XCTAssertTrue(title.waitForExistence(timeout: 6), "B-15: Type cards not shown. Labels: \(app.labelSnapshot().sorted())")
        shot("B-15", "type-cards")
        dump("B-15", "type-cards")
        title.tap()
        title.typeText("Hand Made Set")
        for index in 1...2 {
            let term = app.textFields["Card \(index) term"]
            XCTAssertTrue(term.waitForExistence(timeout: 3), "No term field \(index)")
            term.tap()
            term.typeText("Term \(index)")
            let definition = app.textFields["Card \(index) definition"].exists ? app.textFields["Card \(index) definition"] : app.textViews["Card \(index) definition"]
            definition.tap()
            definition.typeText("Definition \(index)")
        }
        shot("B-15", "filled")
        let save = button(beginningWith: "Save ")
        XCTAssertTrue(save.exists && save.isEnabled, "Save disabled after two complete cards. Labels: \(app.labelSnapshot().sorted())")
        note("B-15", "save label: \(save.label)")
        save.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-15", "after-save")
        dump("B-15", "after-save")
        let tile = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Hand Made Set'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "Set not in Library")
        note("B-15", "tile: \(tile.label)")
    }

    // MARK: C

    private let firstQuestion = "What process turns liquid water into water vapor?"

    private func openMidDraftReview(_ id: String) {
        launch(.midDraft)
        openLibrary()
        let resume = app.buttons["Resume draft"]
        XCTAssertTrue(resume.waitForExistence(timeout: 8), "\(id): no pending draft row")
        resume.tap()
        Thread.sleep(forTimeInterval: 1.5)
        continueToReviewDrafts(id)
        XCTAssertTrue(button(beginningWith: firstQuestion).waitForExistence(timeout: 5), "\(id): first card row missing")
    }

    private var cardRows: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'What ' OR label BEGINSWITH 'How do' OR label BEGINSWITH 'Where '"))
    }

    func test_C_1() {
        launch(.midDraft)
        openLibrary()
        shot("C-1", "library")
        dump("C-1", "library")
        let resume = app.buttons["Resume draft"]
        XCTAssertTrue(resume.waitForExistence(timeout: 8), "No pending draft row")
        resume.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("C-1", "after-resume")
        continueToReviewDrafts("C-1")
        shot("C-1", "review")
        dump("C-1", "review")
        let labels = app.labelSnapshot().sorted()
        note("C-1", "labels: \(labels)")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'DRAFT'")).firstMatch.exists, "No DRAFT · N CARDS header")
        XCTAssertTrue(labels.contains { $0.hasPrefix("From ") }, "Header does not name the source document ('From <title>')")
        XCTAssertTrue(button(beginningWith: "Save 6 cards").exists, "CTA is not 'Save 6 cards'")
        note("C-1", "card rows found: \(cardRows.count)")
        note("C-1", "pill texts: \(labels.filter { $0.contains("¶") || $0.hasPrefix("p.") })")
        let pills = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '¶'")).count
        note("C-1", "source pills in the tree: \(pills) of \(cardRows.count) rows")
        XCTAssertGreaterThan(pills, 0, "No source pills")
    }

    func test_C_2() {
        openMidDraftReview("C-2")
        let row = button(beginningWith: firstQuestion)
        let before = row.frame
        row.tap()
        let question = app.textFields.matching(NSPredicate(format: "value BEGINSWITH %@", firstQuestion)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 4), "No Question field after tap. Labels: \(app.labelSnapshot().sorted())")
        note("C-2", "question field label='\(question.label)' (empty means VoiceOver gets no field name)")
        shot("C-2", "editing")
        dump("C-2", "editing")
        question.typeText(" EDITED")
        let answer = app.textFields.matching(NSPredicate(format: "value BEGINSWITH 'Evaporation is the change'")).firstMatch
        XCTAssertTrue(answer.exists, "No Answer field")
        answer.tap()
        answer.typeText("EDITEDANSWER ")
        shot("C-2", "typed")
        app.lifecycleCheckpoint("C-2", in: self, rotate: true)
        shot("C-2", "after-lc")
        let stillThere = app.textFields.matching(NSPredicate(format: "value CONTAINS 'EDITED'")).firstMatch.exists
            || text(containing: "EDITED").exists
        XCTAssertTrue(stillThere, "Edit lost across LC")
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 4), "No Done")
        done.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("C-2", "done")
        dump("C-2", "done")
        let edited = button(beginningWith: firstQuestion + " EDITED")
        XCTAssertTrue(edited.exists, "Edited question not shown: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(edited.label.contains("EDITEDANSWER"), "Edited answer not shown: \(edited.label)")
        note("C-2", "row frame before \(before) after \(edited.frame)")
        XCTAssertEqual(before.minY, edited.frame.minY, accuracy: 6, "Layout jump after editing")
    }

    func test_C_3() {
        openMidDraftReview("C-3")
        XCTAssertTrue(button(beginningWith: "Save 6 cards").exists)
        button(beginningWith: firstQuestion).swipeLeft()
        Thread.sleep(forTimeInterval: 1)
        shot("C-3", "swiped")
        dump("C-3", "swiped")
        let remove = app.buttons["Remove"]
        XCTAssertTrue(remove.waitForExistence(timeout: 3), "No Remove action after swipe")
        remove.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("C-3", "removed")
        dump("C-3", "removed")
        XCTAssertFalse(button(beginningWith: firstQuestion).exists, "Card still present")
        XCTAssertTrue(button(beginningWith: "Save 5 cards").exists, "CTA did not drop to 5: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.buttons["Undo"].exists, "No Undo")
    }

    func test_C_4() {
        openMidDraftReview("C-4")
        var removed = 0
        for step in 1...14 {
            guard cardRows.count > 0 else { break }
            cardRows.firstMatch.swipeLeft()
            let remove = app.buttons["Remove"]
            guard remove.waitForExistence(timeout: 3) else {
                shot("C-4", "no-remove-step\(step)")
                continue
            }
            remove.tap()
            removed += 1
            Thread.sleep(forTimeInterval: 1)
        }
        note("C-4", "removed \(removed) cards, rows left \(cardRows.count)")
        XCTAssertEqual(cardRows.count, 0, "C-4: could not remove every card")
        // Undo times out 5 s after the last removal, so it is read before the evidence capture below.
        XCTAssertTrue(app.staticTexts["No cards left"].waitForExistence(timeout: 2), "C-4: no 'No cards left' state")
        XCTAssertTrue(app.buttons["Undo"].exists, "C-4: no Undo in the empty state")
        shot("C-4", "all-removed")
        dump("C-4", "all-removed")
        note("C-4", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank with zero cards")
        let save = button(beginningWith: "Save")
        note("C-4", "save exists=\(save.exists)")
        XCTAssertFalse(save.exists, "C-4: a Save CTA is offered with 0 cards (there is no 'Save 0 cards')")
        XCTAssertTrue(app.staticTexts["No cards left"].exists, "C-4: 'No cards left' state gone")
        let discard = app.navigationBars.buttons["Discard"]
        XCTAssertTrue(discard.exists, "C-4: no Discard toolbar button. Labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.navigationBars["Draft cards"].exists, "Review drafts screen gone")
    }

    func test_C_5() {
        openMidDraftReview("C-5")
        let pill = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '¶'")).firstMatch
        XCTAssertTrue(pill.exists, "No source pill")
        let before = app.labelSnapshot()
        pill.tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("C-5", "after-pill-tap")
        dump("C-5", "after-pill-tap")
        let after = app.labelSnapshot()
        note("C-5", "new labels after tap: \(after.subtracting(before).sorted()); lost: \(before.subtracting(after).sorted())")
        let excerpt = text(containing: "The water cycle describes").exists
        let editing = app.textFields.matching(NSPredicate(format: "value BEGINSWITH 'What process'")).firstMatch.exists
        note("C-5", "excerpt shown: \(excerpt); card went into edit mode instead: \(editing)")
        XCTAssertTrue(excerpt || (!editing && after != before), "Source pill does nothing useful on tap (edit mode: \(editing))")
    }

    func test_C_6() {
        openMidDraftReview("C-6")
        button(beginningWith: firstQuestion).tap()
        let question = app.textFields.matching(NSPredicate(format: "value BEGINSWITH %@", firstQuestion)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 4))
        question.typeText(" PERSISTED")
        app.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1)
        button(beginningWith: "What provides the initial energy").swipeLeft()
        app.buttons["Remove"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(button(beginningWith: "Save 5 cards").exists, "Removal did not register")
        shot("C-6", "before-terminate")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("C-6", "after-relaunch-library")
        dump("C-6", "after-relaunch-library")
        let resume = app.buttons["Resume draft"]
        XCTAssertTrue(resume.waitForExistence(timeout: 8), "Draft row gone after relaunch")
        note("C-6", "row: \(app.labelSnapshot().filter { $0.contains("drafted") })")
        resume.tap()
        Thread.sleep(forTimeInterval: 1.5)
        continueToReviewDrafts("C-6")
        shot("C-6", "after-relaunch-review")
        dump("C-6", "after-relaunch-review")
        XCTAssertTrue(button(beginningWith: firstQuestion + " PERSISTED").exists, "Edit lost after relaunch: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(button(beginningWith: "What provides the initial energy").exists, "Removed card came back")
        XCTAssertTrue(button(beginningWith: "Save 5 cards").exists, "CTA not 5 after relaunch")
    }

    func test_C_7() {
        openMidDraftReview("C-7")
        let save = button(beginningWith: "Save 6 cards")
        XCTAssertTrue(save.exists)
        save.tap()
        let watch = watchFrames("C-7", "after-save", seconds: 4)
        shot("C-7", "after-save")
        dump("C-7", "after-save")
        XCTAssertEqual(watch.blankFrames, 0, "Blank frames after Save")
        XCTAssertTrue(app.navigationBars["Library"].exists || app.staticTexts["Library"].exists, "Not on Library")
        let tile = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS 'Water Cycle'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "No set tile")
        note("C-7", "tile: \(tile.label)")
        XCTAssertTrue(tile.label.contains("6 cards"), "Tile does not say 6 cards: \(tile.label)")
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Draft row still present")
    }

    func test_C_8() {
        launch(.midDraft)
        openLibrary()
        let discard = app.buttons["Discard draft"]
        XCTAssertTrue(discard.waitForExistence(timeout: 8), "No Discard draft")
        discard.tap()
        Thread.sleep(forTimeInterval: 1)
        shot("C-8", "row-confirmation")
        dump("C-8", "row-confirmation")
        let alert = app.alerts["Discard draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "No confirmation alert from the row")
        note("C-8", "alert texts: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(app.buttons["Resume draft"].exists, "Draft gone after Cancel")
        discard.tap()
        app.alerts["Discard draft?"].buttons["Discard"].tap()
        let watch = watchFrames("C-8", "after-discard", seconds: 3)
        shot("C-8", "after-discard")
        XCTAssertEqual(watch.blankFrames, 0)
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Draft row still there")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("C-8", "after-relaunch")
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Draft came back after relaunch")
    }

    func test_C_8b() {
        launch(.midDraft)
        openLibrary()
        app.buttons["Resume draft"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 6), "No Cancel on Scan Preview")
        app.buttons["Cancel"].tap()
        let alert = app.alerts["Discard draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "No confirmation from Scan Preview")
        note("C-8", "preview alert: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        shot("C-8", "preview-confirmation")
        alert.buttons["Discard"].tap()
        Thread.sleep(forTimeInterval: 2)
        shot("C-8", "preview-after-discard")
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Draft row still there")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        XCTAssertFalse(app.buttons["Resume draft"].exists, "Draft came back after relaunch")
    }
}

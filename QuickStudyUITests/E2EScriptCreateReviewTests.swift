import XCTest

/// Sections B (Create) and C (Review Cards and Save) of audit/e2e-test-script.md. One method per step ID.
/// Seed before each test: `Scripts/seed.sh <udid> onboardedEmpty` for B, `midDraft` for C. A draft left behind by one
/// test makes the next New Set raise "Replace your draft?", so seed per test rather than per class.
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

    private func assertReachedReview(_ id: String, _ outcome: GenerationOutcome) {
        switch outcome {
        case .ready:
            note(id, "ready card: \(readyCard.label)")
            tapReviewCard(id)
        case let .failure(title):
            XCTFail("\(id): drafting failed with '\(title)'. Labels: \(app.labelSnapshot().sorted())")
            return
        case .timedOut:
            XCTFail("\(id): no result within the timeout")
            return
        }
        shot(id, "review-cards")
        dump(id, "review-cards")
        note(id, "review labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(saveCardsButton.exists, "\(id): no Save Cards checkmark")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "\(id): blank on Review Cards")
    }

    private func openPasteSheet(_ id: String) {
        chooseSource(id, label: Source.paste)
        XCTAssertTrue(app.navigationBars["Paste Text"].waitForExistence(timeout: QSApp.uiTimeout),
                      "\(id): Paste Text sheet did not open. Labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.textViews.firstMatch.waitForExistence(timeout: QSApp.uiTimeout), "\(id): no paste editor")
    }

    // MARK: B

    func test_B_1() {
        launch(.onboardedEmpty)
        openNewSetSheet("B-1")
        shot("B-1", "sheet")
        dump("B-1", "sheet")
        note("B-1", "labels: \(app.labelSnapshot().sorted())")
        for row in [Source.photo, Source.pdf, Source.paste] {
            XCTAssertTrue(app.buttons[row].exists, "Source row '\(row)' missing")
        }
        XCTAssertTrue(app.staticTexts["Works best with 1 to 10 pages of notes."].exists, "Sheet footer missing")
        XCTAssertTrue(app.navigationBars["New Set"].buttons["Close"].exists, "No Close button")
        app.lifecycleCheckpoint("B-1", in: self, rotate: true)
        shot("B-1", "after-lc")
        XCTAssertTrue(app.navigationBars["New Set"].exists, "Sheet gone after LC")
        app.navigationBars["New Set"].buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["New Set"].waitUntilGone(), "Close did not dismiss the sheet")
    }

    /// The simulator has no document camera, so New Set must not offer Scan. The Camera Unavailable alert is still
    /// reachable from onboarding's "Scan a page" (A-4).
    func test_B_2() {
        launch(.onboardedEmpty)
        openNewSetSheet("B-2")
        shot("B-2", "sheet")
        XCTAssertFalse(button(beginningWith: "Scan Document").exists, "Scan offered on a simulator without a document camera")
        XCTAssertFalse(text(containing: "Fastest · recommended").exists, "Scan row subtitle shown without a scan row")
    }

    func test_B_3() {
        launch(.onboardedEmpty)
        chooseSource("B-3", label: Source.photo)
        pickFirstPhoto("B-3")
        let outcome = finishGeneration("B-3")
        assertReachedReview("B-3", outcome)
    }

    func test_B_4() {
        launch(.onboardedEmpty)
        chooseSource("B-4", label: Source.pdf)
        pickFile("B-4", named: "small.pdf")
        let sawDrafting = waitForDrafting("B-4", timeout: 20)
        shot("B-4", "drafting-first")
        dump("B-4", "drafting-first")
        note("B-4", "drafting visible: \(sawDrafting); card: \(draftingCard.exists ? draftingCard.label : "none")")
        XCTAssertTrue(sawDrafting, "B-4: no drafting status card")
        XCTAssertFalse(app.navigationBars["Choose Pages"].exists, "Choose Pages shown for a 3-page PDF")
        if sawDrafting {
            XCTAssertTrue(draftingCard.label.hasPrefix("Drafting small"), "Status card does not name the PDF: \(draftingCard.label)")
            softLifecycle("B-4", name: "after-lc-drafting")
        }
        let outcome = finishGeneration("B-4")
        assertReachedReview("B-4", outcome)
        let pills = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Source, page'")).count
        note("B-4", "page source pills visible: \(pills)")
        XCTAssertGreaterThan(pills, 0, "No page-numbered Source pills on a PDF draft")
    }

    func test_B_5() {
        launch(.onboardedEmpty)
        openPasteSheet("B-5")
        let editor = app.textViews.firstMatch
        let notes = fixtureText("notes.txt")
        XCTAssertFalse(notes.isEmpty, "notes.txt fixture unreadable")
        UIPasteboard.general.string = notes
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
            editor.typeText(notes)
        }
        shot("B-5", "pasted")
        dump("B-5", "pasted")
        note("B-5", "labels: \(app.labelSnapshot().sorted())")
        let summary = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+ words · about [0-9]+ cards?$")).firstMatch
        XCTAssertTrue(summary.exists, "No 'N words · about M cards' summary")
        XCTAssertTrue(app.element(labelContaining: "On this iPhone").exists, "Engine chip does not say On this iPhone before consent")
        XCTAssertFalse(text(containing: "free left").exists, "Paste sheet still shows the free-generations counter")
        tapDraftCards("B-5")
        let outcome = finishGeneration("B-5")
        assertReachedReview("B-5", outcome)
    }

    func test_B_6() {
        launch(.onboardedEmpty)
        openPasteSheet("B-6")
        typeIntoPasteSheet("B-6", text: fixtureText("notes-short.txt").trimmingCharacters(in: .whitespacesAndNewlines))
        shot("B-6", "typed")
        tapDraftCards("B-6")
        let outcome = finishGeneration("B-6")
        note("B-6", "result: \(outcome)")
        switch outcome {
        case .ready: assertReachedReview("B-6", outcome)
        case .failure:
            XCTAssertTrue(app.buttons["Try Again"].exists || app.buttons["Edit Text"].exists, "Failure card offers no recovery")
            XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after failure")
        case .timedOut: XCTFail("B-6: no result")
        }
    }

    func test_B_7() {
        launch(.onboardedEmpty)
        openPasteSheet("B-7")
        let draft = draftCardsButton
        XCTAssertTrue(draft.waitForExistence(timeout: 4))
        shot("B-7", "empty")
        note("B-7", "empty: Draft Cards enabled=\(draft.isEnabled)")
        XCTAssertFalse(draft.isEnabled, "Draft Cards enabled with an empty editor")
        app.textViews.firstMatch.tap()
        app.textViews.firstMatch.typeText("   \n  \n   ")
        shot("B-7", "whitespace")
        note("B-7", "whitespace: Draft Cards enabled=\(draft.isEnabled)")
        XCTAssertFalse(draft.isEnabled, "Draft Cards enabled with whitespace only")
        app.navigationBars["Paste Text"].buttons["Close"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(isDrafting, "Drafting started after closing an empty paste sheet")
        XCTAssertFalse(dismissFailureButton.exists, "A failure card appeared after closing an empty paste sheet")
        shot("B-7", "end")
    }

    /// large.pdf has 320 pages, so Choose Pages opens with the first 10 selected.
    private func openChoosePages(_ id: String) {
        chooseSource(id, label: Source.pdf)
        pickFile(id, named: "large.pdf")
        XCTAssertTrue(app.navigationBars["Choose Pages"].waitForExistence(timeout: 30),
                      "\(id): Choose Pages not shown for a 320-page PDF. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 1)
    }

    private func scrollToPage(_ number: Int) -> XCUIElement {
        let cell = app.buttons["Page \(number)"]
        var attempts = 0
        while !(cell.exists && cell.isHittable), attempts < 6 {
            app.scrollViews.firstMatch.swipeUp(velocity: .slow)
            attempts += 1
        }
        return cell
    }

    func test_B_8() {
        launch(.onboardedEmpty)
        openChoosePages("B-8")
        shot("B-8", "choose-pages")
        dump("B-8", "choose-pages")
        note("B-8", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.staticTexts["large · 320 pages"].exists, "No file name and page count")
        XCTAssertTrue(app.staticTexts["Tap pages to choose up to 10."].exists)
        XCTAssertTrue(app.staticTexts["Pages 1 to 10 selected"].exists, "Default selection is not pages 1 to 10")
        XCTAssertTrue(text(containing: "about 1 minute on this iPhone").exists, "No time estimate")
        XCTAssertTrue(app.buttons["Draft 10 Pages"].exists, "No Draft 10 Pages")
        XCTAssertEqual(app.buttons["Page 1"].value as? String, "Selected")

        let eleven = scrollToPage(11)
        XCTAssertTrue(eleven.exists, "No Page 11 cell")
        eleven.tap()
        XCTAssertTrue(app.staticTexts["You can choose up to 10 pages."].waitForExistence(timeout: 2), "No cap note at 11 pages")
        shot("B-8", "cap-note")
        XCTAssertEqual(eleven.value as? String, "Not selected", "An 11th page was selected")
        let ten = app.buttons["Page 10"]
        ten.tap()
        XCTAssertTrue(app.staticTexts["Pages 1 to 9 selected"].waitForExistence(timeout: 2), "Deselecting page 10 did not update the summary")
        XCTAssertTrue(app.buttons["Draft 9 Pages"].exists)
        eleven.tap()
        XCTAssertTrue(app.staticTexts["10 pages selected"].waitForExistence(timeout: 2), "Non-contiguous summary wrong: \(app.labelSnapshot().sorted())")
        ten.tap()
        XCTAssertTrue(app.staticTexts["You can choose up to 10 pages."].waitForExistence(timeout: 2))
        eleven.tap()
        ten.tap()
        XCTAssertTrue(app.staticTexts["Pages 1 to 10 selected"].waitForExistence(timeout: 2))

        app.buttons["Draft 10 Pages"].tap()
        let started = Date()
        var sampledReading = false
        while !(isDrafting && draftingCard.label.contains("Drafting cards")), Date().timeIntervalSince(started) < 120 {
            if app.buttons["Not Now"].exists { declineConsentIfAsked("B-8", wait: 0.5) }
            if !sampledReading, draftingCard.exists, draftingCard.label.contains("Reading page") {
                sampledReading = true
                shot("B-8", "reading")
                note("B-8", "reading: \(draftingCard.label) at \(Int(Date().timeIntervalSince(started))) s")
                XCTAssertTrue(draftingCard.label.hasSuffix("of 10"), "Reading counts all 320 pages, not the 10 chosen: \(draftingCard.label)")
            }
            if let title = Self.failureTitles.first(where: { failureCard($0).exists }) {
                shot("B-8", "failure")
                XCTFail("B-8: large.pdf failed with '\(title)'. Labels: \(app.labelSnapshot().sorted())")
                return
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        guard isDrafting else {
            shot("B-8", "TIMEOUT-120s")
            dump("B-8", "TIMEOUT-120s")
            XCTFail("B-8: no 'Drafting cards' status within 120 s. Labels: \(app.labelSnapshot().sorted())")
            return
        }
        let firstLabel = draftingCard.label
        note("B-8", "drafting after \(Int(Date().timeIntervalSince(started))) s: \(firstLabel)")
        XCTAssertTrue(firstLabel.hasPrefix("Drafting large"), "Status card does not name the PDF: \(firstLabel)")
        shot("B-8", "drafting")
        dump("B-8", "drafting")
        var progressed = false
        let watchStart = Date()
        while Date().timeIntervalSince(watchStart) < 60, isDrafting {
            if draftingCard.label != firstLabel {
                note("B-8", "progress: '\(firstLabel)' -> '\(draftingCard.label)' after \(Int(Date().timeIntervalSince(watchStart))) s")
                progressed = true
                break
            }
            Thread.sleep(forTimeInterval: 1)
        }
        XCTAssertTrue(progressed || !isDrafting, "B-8: status stalled at '\(firstLabel)' for 60 s")
        shot("B-8", "before-cancel")
        guard isDrafting else { return }
        cancelDraftingButton.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-8", "after-cancel")
        note("B-8", "labels after Cancel: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(isDrafting, "B-8: still drafting after Cancel drafting")
        XCTAssertFalse(dismissFailureButton.exists, "B-8: a user cancel left a failure card")
    }

    func test_B_8b() {
        launch(.onboardedEmpty)
        openChoosePages("B-8b")
        app.navigationBars["Choose Pages"].buttons["Close"].tap()
        XCTAssertTrue(app.navigationBars["Choose Pages"].waitUntilGone(), "Close did not dismiss Choose Pages")
        Thread.sleep(forTimeInterval: 3)
        shot("B-8b", "after-close")
        XCTAssertFalse(isDrafting, "Closing Choose Pages started a draft")
        XCTAssertFalse(dismissFailureButton.exists, "Closing Choose Pages left a failure card")
        XCTAssertFalse(app.buttons["Not Now"].exists, "Closing Choose Pages asked for cloud consent")
    }

    func test_B_9() {
        launch(.onboardedEmpty)
        chooseSource("B-9", label: Source.pdf)
        pickFile("B-9", named: "corrupt.pdf")
        let outcome = finishGeneration("B-9", timeout: 30)
        note("B-9", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertEqual(outcome, .failure("We couldn't open this PDF"), "B-9: expected the unreadable-PDF card")
        XCTAssertTrue(failureCard("We couldn't open this PDF").label.contains("It may be damaged or password protected."),
                      "Failure card detail missing")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank)
        XCTAssertTrue(app.buttons["Try Again"].exists, "No Try Again on the failure card")
        XCTAssertTrue(createButton.isHittable, "The failure blocks the Library")
        app.lifecycleCheckpoint("B-9", in: self)

        app.buttons["Try Again"].tap()
        let picker = XCUIApplication(bundleIdentifier: Self.filesPickerBundleID)
        XCTAssertTrue(picker.buttons["Cancel"].waitForExistence(timeout: 10), "Try Again did not reopen the Files picker")
        shot("B-9", "try-again-picker")
        picker.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(dismissFailureButton.exists, "Failure card still shown after Try Again")

        chooseSource("B-9b", label: Source.pdf)
        pickFile("B-9b", named: "corrupt.pdf")
        XCTAssertEqual(finishGeneration("B-9b", timeout: 30), .failure("We couldn't open this PDF"))
        dismissFailureButton.tap()
        XCTAssertTrue(dismissFailureButton.waitUntilGone(timeout: 3), "Dismiss did not remove the failure card")
    }

    /// With no on-device model, Not Now leaves nothing that can draft, so the app routes to Type cards.
    func test_B_10() {
        launch(.onboardedEmpty, .noAppleIntelligence)
        openPasteSheet("B-10")
        XCTAssertFalse(app.buttons["Not Now"].exists, "Consent asked before the source was read")
        typeIntoPasteSheet("B-10", text: shortNote)
        tapDraftCards("B-10")
        let notNow = app.buttons["Not Now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 6), "B-10: no consent sheet once the draft would leave the iPhone")
        shot("B-10", "consent")
        notNow.tap()
        XCTAssertTrue(app.textFields["Set title"].waitForExistence(timeout: 6),
                      "B-10: Not Now without an on-device model did not open Type cards. Labels: \(app.labelSnapshot().sorted())")
        shot("B-10", "type-cards")
        XCTAssertFalse(isDrafting, "Drafting started after Not Now with no on-device model")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank end state")
    }

    func test_B_11() {
        launch(.allowanceSpent)
        openLibrary()
        shot("B-11", "library")
        dump("B-11", "library")
        note("B-11", "library labels: \(app.labelSnapshot().sorted())")
        createButton.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-11", "after-new-set")
        dump("B-11", "after-new-set")
        note("B-11", "after New Set labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank")
        let paywall = text(containing: "QuickStudy Pro").exists || app.buttons["Restore Subscription"].exists
        XCTAssertTrue(paywall, "No paywall after New Set with the allowance spent")
        XCTAssertFalse(app.navigationBars["New Set"].exists, "New Set sheet opened with no generations left")
    }

    func test_B_12() {
        launch(.hostedConsentDeclined, .noAppleIntelligence)
        openLibrary()
        shot("B-12", "library")
        createButton.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-12", "after-new-set")
        dump("B-12", "after-new-set")
        note("B-12", "after New Set labels: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank")
        XCTAssertTrue(app.textFields["Set title"].waitForExistence(timeout: 4), "Manual-only user did not get Type cards")
        XCTAssertFalse(app.buttons["Allow"].exists, "Cloud consent re-asked after decline")
    }

    /// Checks the consent copy. Allow is never tapped: it would send the draft to the hosted server.
    func test_B_13() {
        launch(.onboardedEmpty, .noAppleIntelligence)
        openPasteSheet("B-13")
        typeIntoPasteSheet("B-13", text: shortNote)
        tapDraftCards("B-13")
        let notNow = app.buttons["Not Now"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 6), "B-13: consent sheet not shown. Labels: \(app.labelSnapshot().sorted())")
        shot("B-13", "consent")
        dump("B-13", "consent")
        let labels = app.labelSnapshot().sorted()
        note("B-13", "consent labels: \(labels)")
        XCTAssertTrue(app.staticTexts["Draft This Set in the Cloud?"].exists, "Consent title for an iPhone without a model is wrong")
        XCTAssertTrue(app.buttons["Allow"].exists, "No Allow")
        XCTAssertTrue(app.buttons["Privacy Policy"].exists || app.links["Privacy Policy"].exists, "No Privacy Policy link")
        let joined = labels.joined(separator: " ").lowercased()
        XCTAssertTrue(joined.contains("anthropic") || joined.contains("claude"), "Consent copy does not name Anthropic/Claude")
        XCTAssertTrue(joined.contains("30 days"), "Consent copy does not mention 30-day deletion")
        XCTAssertFalse(joined.contains("not stored"), "Consent copy says 'not stored'")
        XCTAssertFalse(labels.contains { $0.contains("\u{2014}") }, "Em dash in consent copy")
        app.lifecycleCheckpoint("B-13", in: self)
        XCTAssertTrue(notNow.exists, "Consent sheet lost after LC")
        notNow.tap()
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertFalse(app.buttons["Allow"].exists, "Consent sheet still up after Not Now")
    }

    func test_B_14() {
        launch(.onboardedEmpty)
        openPasteSheet("B-14")
        typeIntoPasteSheet("B-14", text: shortNote)
        tapDraftCards("B-14")
        XCTAssertTrue(waitForDrafting("B-14", timeout: 20), "B-14: drafting status never appeared")
        Thread.sleep(forTimeInterval: 2)
        shot("B-14", "drafting")
        note("B-14", "drafting card: \(draftingCard.label)")
        XCTAssertTrue(createButton.isHittable, "Drafting blocks the Library")
        app.tapTab("Today")
        Thread.sleep(forTimeInterval: 1)
        app.tapTab("Library")
        XCTAssertTrue(isDrafting, "Drafting status lost after switching tabs")
        cancelDraftingButton.tap()
        Thread.sleep(forTimeInterval: 2)
        shot("B-14", "after-cancel")
        dump("B-14", "after-cancel")
        XCTAssertFalse(isDrafting, "Still drafting after Cancel drafting")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "Blank after Cancel")
        XCTAssertFalse(dismissFailureButton.exists, "Failure card after a user Cancel")
        Thread.sleep(forTimeInterval: 45)
        shot("B-14", "after-cancel-45s")
        XCTAssertFalse(readyCard.exists || reviewCardButton.exists, "Cancelled draft turned up as ready later")

        openPasteSheet("B-14b")
        app.textViews.firstMatch.tap()
        let existing = (app.textViews.firstMatch.value as? String) ?? ""
        if existing.count < 50 { app.textViews.firstMatch.typeText(shortNote) }
        tapDraftCards("B-14b")
        XCTAssertTrue(waitForDrafting("B-14b", timeout: 20), "B-14b: drafting status never appeared")
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
        createButton.tap()
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

    /// Consent is only asked when a draft would leave the iPhone. Once declined, drafts run on this iPhone unasked.
    func test_B_16() {
        launch(.hostedConsentDeclined)
        openPasteSheet("B-16")
        typeIntoPasteSheet("B-16", text: shortNote)
        tapDraftCards("B-16")
        let deadline = Date().addingTimeInterval(20)
        var asked = false
        while Date() < deadline, !isDrafting {
            asked = asked || app.buttons["Allow"].exists
            Thread.sleep(forTimeInterval: 0.3)
        }
        shot("B-16", "after-draft-cards")
        XCTAssertFalse(asked, "Consent asked after it was declined")
        XCTAssertTrue(isDrafting, "No drafting status")
        cancelDraftingButton.tap()
    }

    /// Starting a second import while one drafts asks before cancelling it.
    func test_B_17() {
        launch(.onboardedEmpty)
        startShortGeneration("B-17")
        createButton.tap()
        let alert = app.alerts["Replace your draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4), "No Replace your draft? alert while drafting")
        note("B-17", "alert: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        XCTAssertTrue(alert.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'QuickStudy is still drafting '")).firstMatch.exists,
                      "Alert does not say a draft is in progress")
        shot("B-17", "alert")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(isDrafting, "Cancel on the alert stopped the draft")
        createButton.tap()
        app.alerts["Replace your draft?"].buttons["Replace"].tap()
        XCTAssertTrue(app.navigationBars["New Set"].waitForExistence(timeout: QSApp.uiTimeout), "Replace did not open New Set")
        XCTAssertFalse(isDrafting, "Replace left the old draft running")
    }

    // MARK: C

    private let firstQuestion = "What process turns liquid water into water vapor?"

    private func openMidDraftReview(_ id: String) {
        launch(.midDraft)
        openDraftReview(id)
        XCTAssertTrue(button(beginningWith: firstQuestion).waitForExistence(timeout: 5), "\(id): first card row missing")
    }

    private var cardRows: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'What ' OR label BEGINSWITH 'How do' OR label BEGINSWITH 'Where '"))
    }

    private func headerSays(_ cards: Int) -> Bool {
        app.element(labelContaining: "\(cards) \(cards == 1 ? "card" : "cards") from Pasted Notes").exists
    }

    func test_C_1() {
        launch(.midDraft)
        openLibrary()
        shot("C-1", "library")
        dump("C-1", "library")
        XCTAssertTrue(readyCard.waitForExistence(timeout: 8), "No ready status card")
        note("C-1", "ready card: \(readyCard.label)")
        XCTAssertTrue(readyCard.label.hasPrefix("The Water Cycle. The water cycle is ready"), "Ready card title: \(readyCard.label)")
        XCTAssertTrue(readyCard.label.contains("6 cards drafted"), "Ready card detail: \(readyCard.label)")
        tapReviewCard("C-1")
        shot("C-1", "review")
        dump("C-1", "review")
        let labels = app.labelSnapshot().sorted()
        note("C-1", "labels: \(labels)")
        XCTAssertTrue(headerSays(6), "Header is not '6 cards from Pasted Notes'")
        XCTAssertTrue(app.element(labelContaining: "Tap a card to edit. Swipe left to delete.").exists, "No edit/delete hint")
        XCTAssertTrue(saveCardsButton.exists && saveCardsButton.isEnabled, "Save Cards missing or disabled")
        XCTAssertTrue(reviewCardsNavBar.buttons["Close"].exists, "No Close")
        note("C-1", "card rows found: \(cardRows.count)")
        let pills = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Source'")).count
        note("C-1", "source pills in the tree: \(pills) of \(cardRows.count) rows")
        XCTAssertGreaterThan(pills, 0, "No Source pills")
        let regenerate = app.buttons["Regenerate"]
        for _ in 0..<4 where !regenerate.isHittable { app.swipeUp() }
        XCTAssertTrue(regenerate.exists, "No Regenerate below the cards")
    }

    func test_C_2() {
        openMidDraftReview("C-2")
        let row = button(beginningWith: firstQuestion)
        let before = row.frame
        row.tap()
        let question = app.textFields.matching(NSPredicate(format: "value BEGINSWITH %@", firstQuestion)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 4), "No Question field after tap. Labels: \(app.labelSnapshot().sorted())")
        note("C-2", "question field label='\(question.label)'")
        XCTAssertEqual(question.label, "Question", "Question field has no accessibility label")
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
            || button(beginningWith: firstQuestion + " EDITED").exists
        XCTAssertTrue(stillThere, "Edit lost across LC")
        let done = app.buttons["Done"]
        if done.waitForExistence(timeout: 2) {
            done.tap()
        } else {
            note("C-2", "row left edit mode during LC (focus loss closes it)")
        }
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
        XCTAssertTrue(headerSays(6))
        deleteCard(button(beginningWith: firstQuestion))
        shot("C-3", "removed")
        dump("C-3", "removed")
        XCTAssertFalse(button(beginningWith: firstQuestion).exists, "Card still present")
        XCTAssertTrue(headerSays(5), "Header did not drop to 5: \(app.labelSnapshot().sorted())")
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.exists, "No Undo")
        undo.tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(button(beginningWith: firstQuestion).exists, "Undo did not restore the card")
        XCTAssertTrue(headerSays(6), "Header not back to 6 after Undo")
        deleteCard(button(beginningWith: firstQuestion))
        openSaveSheet("C-3", cards: 5)
    }

    func test_C_4() {
        openMidDraftReview("C-4")
        var removed = 0
        for _ in 1...10 {
            guard cardRows.count > 0 else { break }
            let before = cardRows.count
            deleteCard(cardRows.firstMatch)
            if cardRows.count < before { removed += 1 }
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
        XCTAssertTrue(saveCardsButton.exists, "C-4: Save Cards checkmark gone")
        XCTAssertFalse(saveCardsButton.isEnabled, "C-4: Save Cards enabled with 0 cards")
        XCTAssertTrue(app.staticTexts["Undo the last removal, or discard this draft."].exists)
        XCTAssertFalse(app.buttons["Regenerate"].exists, "Regenerate offered with no cards")
        let discard = app.buttons["Discard"]
        XCTAssertTrue(discard.exists, "C-4: no Discard in the empty state")
        discard.tap()
        let alert = app.alerts["Discard Draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3), "C-4: no Discard Draft? confirmation")
        note("C-4", "alert: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(reviewCardsNavBar.exists, "Review Cards gone after cancelling Discard")
    }

    func test_C_5() {
        openMidDraftReview("C-5")
        let pill = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Source'")).firstMatch
        XCTAssertTrue(pill.exists, "No Source pill")
        note("C-5", "pill: \(pill.label)")
        pill.tap()
        let sourceBar = app.navigationBars.matching(NSPredicate(format: "identifier BEGINSWITH 'Source'")).firstMatch
        XCTAssertTrue(sourceBar.waitForExistence(timeout: 4), "Card Source sheet did not open. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 1)
        shot("C-5", "card-source")
        dump("C-5", "card-source")
        note("C-5", "source sheet: \(sourceBar.identifier); labels \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.element(labelContaining: "The water cycle describes").exists, "Passage not shown")
        let fullPage = app.buttons["Show Full Page"]
        XCTAssertTrue(fullPage.exists, "No Show Full Page")
        fullPage.tap()
        XCTAssertTrue(app.buttons["Show Passage"].waitForExistence(timeout: 3), "Show Full Page did not toggle")
        shot("C-5", "full-page")
        app.buttons["Show Passage"].tap()
        XCTAssertTrue(fullPage.waitForExistence(timeout: 3), "Show Passage did not toggle back")
        sourceBar.buttons["Close"].tap()
        XCTAssertTrue(sourceBar.waitUntilGone(), "Close did not dismiss Card Source")
        let editing = app.textFields.matching(NSPredicate(format: "value BEGINSWITH 'What process'")).firstMatch.exists
        XCTAssertFalse(editing, "Tapping the Source pill put the card into edit mode")
        XCTAssertTrue(reviewCardsNavBar.exists, "Review Cards gone after closing Card Source")
    }

    func test_C_6() {
        openMidDraftReview("C-6")
        button(beginningWith: firstQuestion).tap()
        let question = app.textFields.matching(NSPredicate(format: "value BEGINSWITH %@", firstQuestion)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 4))
        question.typeText(" PERSISTED")
        app.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1)
        deleteCard(button(beginningWith: "What provides the initial energy"))
        XCTAssertTrue(headerSays(5), "Removal did not register")
        shot("C-6", "before-terminate")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("C-6", "after-relaunch-library")
        dump("C-6", "after-relaunch-library")
        XCTAssertTrue(readyCard.waitForExistence(timeout: 8), "Ready card gone after relaunch")
        note("C-6", "card: \(readyCard.label)")
        XCTAssertTrue(readyCard.label.contains("5 cards drafted"), "Ready card does not count 5 cards: \(readyCard.label)")
        tapReviewCard("C-6")
        shot("C-6", "after-relaunch-review")
        dump("C-6", "after-relaunch-review")
        XCTAssertTrue(button(beginningWith: firstQuestion + " PERSISTED").exists, "Edit lost after relaunch: \(app.labelSnapshot().sorted())")
        XCTAssertFalse(button(beginningWith: "What provides the initial energy").exists, "Removed card came back")
        XCTAssertTrue(headerSays(5), "Header not 5 after relaunch")
    }

    /// Only sample sets or nothing to add to, so the Save sheet offers New Set only.
    func test_C_7() {
        openMidDraftReview("C-7")
        openSaveSheet("C-7", cards: 6)
        shot("C-7", "save-sheet")
        dump("C-7", "save-sheet")
        note("C-7", "labels: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(app.staticTexts["NAME"].exists, "No NAME header")
        let name = app.textFields["Name"]
        XCTAssertTrue(name.exists, "No Name field")
        XCTAssertEqual(name.value as? String, "The Water Cycle. The water cycle", "Name is not the suggested title")
        XCTAssertTrue(app.staticTexts["Suggested from your notes. You can rename it anytime."].exists)
        XCTAssertTrue(addToExistingSegment.exists, "No Add to Existing segment")
        XCTAssertFalse(addToExistingSegment.isEnabled, "Add to Existing enabled with no sets of the user's own")
        XCTAssertTrue(app.staticTexts["You have no sets of your own to add these cards to yet."].exists, "No explanation for the disabled segment")
        app.buttons["Clear Name"].tap()
        name.tap()
        name.typeText("E2E Water Cycle")
        confirmSave(cards: 6)
        let watch = watchFrames("C-7", "after-save", seconds: 4)
        shot("C-7", "after-save")
        dump("C-7", "after-save")
        XCTAssertEqual(watch.blankFrames, 0, "Blank frames after Save")
        XCTAssertTrue(app.navigationBars["Library"].exists || app.staticTexts["Library"].exists, "Not on Library")
        let tile = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'E2E Water Cycle'")).firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), "No set tile with the new name")
        note("C-7", "tile: \(tile.label)")
        XCTAssertTrue(tile.label.contains("6 cards"), "Tile does not say 6 cards: \(tile.label)")
        XCTAssertFalse(readyCard.exists || reviewCardButton.exists, "Ready card still present after Save")
    }

    func test_C_8() {
        launch(.midDraft)
        openLibrary()
        var alert = openDiscardAlert("C-8")
        shot("C-8", "confirmation")
        dump("C-8", "confirmation")
        let texts = alert.staticTexts.allElementsBoundByIndex.map(\.label)
        note("C-8", "alert texts: \(texts)")
        XCTAssertTrue(texts.contains("The 6 drafted cards will be deleted. This used one of your free generations."), "Discard warning: \(texts)")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(reviewCardButton.exists, "Draft gone after Cancel")
        alert = openDiscardAlert("C-8")
        alert.buttons["Discard Draft"].tap()
        let watch = watchFrames("C-8", "after-discard", seconds: 3)
        shot("C-8", "after-discard")
        XCTAssertEqual(watch.blankFrames, 0)
        XCTAssertFalse(readyCard.exists || reviewCardButton.exists, "Ready card still there")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        shot("C-8", "after-relaunch")
        XCTAssertFalse(reviewCardButton.exists, "Draft came back after relaunch")
    }

    /// Close keeps the draft for later; discarding from the empty state removes it for good.
    func test_C_8b() {
        openMidDraftReview("C-8b")
        reviewCardsNavBar.buttons["Close"].tap()
        XCTAssertTrue(reviewCardsNavBar.waitUntilGone(), "Close did not dismiss Review Cards")
        XCTAssertTrue(reviewCardButton.waitForExistence(timeout: 3), "Close lost the draft")
        tapReviewCard("C-8b")
        for _ in 1...10 where cardRows.count > 0 { deleteCard(cardRows.firstMatch) }
        XCTAssertTrue(app.buttons["Discard"].waitForExistence(timeout: 3), "No Discard in the empty state")
        app.buttons["Discard"].tap()
        let alert = app.alerts["Discard Draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.staticTexts["This draft will be deleted. This used one of your free generations."].exists,
                      "Empty-draft warning: \(alert.staticTexts.allElementsBoundByIndex.map(\.label))")
        alert.buttons["Discard Draft"].tap()
        XCTAssertTrue(reviewCardsNavBar.waitUntilGone(), "Review Cards still up after Discard")
        Thread.sleep(forTimeInterval: 1)
        shot("C-8b", "after-discard")
        XCTAssertFalse(reviewCardButton.exists, "Ready card still there")
        app.terminate()
        app.relaunchKeepingState()
        Thread.sleep(forTimeInterval: 3)
        openLibrary()
        XCTAssertFalse(reviewCardButton.exists, "Draft came back after relaunch")
    }

    /// A ready draft is only replaced after the user confirms.
    func test_C_9() {
        launch(.midDraft)
        openLibrary()
        XCTAssertTrue(readyCard.waitForExistence(timeout: 8))
        createButton.tap()
        let alert = app.alerts["Replace your draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4), "No Replace your draft? alert with a ready draft")
        let texts = alert.staticTexts.allElementsBoundByIndex.map(\.label)
        note("C-9", "alert: \(texts)")
        XCTAssertTrue(texts.contains("You have a draft from The Water Cycle. The water cycle waiting. Starting a new set will discard it."),
                      "Replace message: \(texts)")
        alert.buttons["Cancel"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertTrue(readyCard.exists, "Cancel discarded the draft")
        XCTAssertFalse(app.navigationBars["New Set"].exists, "Cancel opened New Set")
        createButton.tap()
        app.alerts["Replace your draft?"].buttons["Replace"].tap()
        XCTAssertTrue(app.navigationBars["New Set"].waitForExistence(timeout: QSApp.uiTimeout), "Replace did not open New Set")
        app.navigationBars["New Set"].buttons["Close"].tap()
        Thread.sleep(forTimeInterval: 1)
        XCTAssertFalse(readyCard.exists, "Replace kept the old draft")
    }

    /// Regenerate asks first when there are edits, then redrafts on this iPhone (no consent is recorded).
    func test_C_10() {
        openMidDraftReview("C-10")
        button(beginningWith: firstQuestion).tap()
        let question = app.textFields.matching(NSPredicate(format: "value BEGINSWITH %@", firstQuestion)).firstMatch
        XCTAssertTrue(question.waitForExistence(timeout: 4))
        question.typeText(" EDITED")
        app.buttons["Done"].tap()
        Thread.sleep(forTimeInterval: 1)
        let regenerate = app.buttons["Regenerate"]
        for _ in 0..<4 where !(regenerate.exists && regenerate.isHittable) { app.swipeUp() }
        XCTAssertTrue(regenerate.isHittable, "Regenerate not reachable")
        regenerate.tap()
        let replace = app.buttons["Replace"]
        XCTAssertTrue(replace.waitForExistence(timeout: 3), "No Replace confirmation with unsaved edits")
        XCTAssertTrue(text(containing: "Replace 6 cards?").exists, "Confirmation title: \(app.labelSnapshot().sorted())")
        XCTAssertTrue(text(containing: "Your edits will be lost.").exists)
        shot("C-10", "confirm")
        app.buttons["Cancel"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        app.swipeDown()
        XCTAssertTrue(button(beginningWith: firstQuestion + " EDITED").exists, "Cancel lost the edit")
        for _ in 0..<4 where !(regenerate.exists && regenerate.isHittable) { app.swipeUp() }
        regenerate.tap()
        XCTAssertTrue(replace.waitForExistence(timeout: 3))
        replace.tap()
        let progress = app.descendants(matching: .any)["Regenerating"]
        let sawProgress = progress.waitForExistence(timeout: 5)
        note("C-10", "Regenerating shown: \(sawProgress)")
        if sawProgress, progress.exists {
            XCTAssertFalse(saveCardsButton.isEnabled, "Save Cards enabled while regenerating")
        }
        let end = Date().addingTimeInterval(QSApp.generationTimeout)
        while progress.exists, Date() < end { Thread.sleep(forTimeInterval: 1) }
        shot("C-10", "after-regenerate")
        dump("C-10", "after-regenerate")
        XCTAssertFalse(progress.exists, "Still regenerating after \(Int(QSApp.generationTimeout)) s")
        XCTAssertFalse(app.alerts["Couldn't regenerate"].exists, "Regenerate failed: \(app.labelSnapshot().sorted())")
        app.swipeDown()
        XCTAssertFalse(button(beginningWith: firstQuestion + " EDITED").exists, "Regenerate kept the edited card")
        XCTAssertTrue(saveCardsButton.isEnabled, "Save Cards disabled after regenerating")
        note("C-10", "labels after regenerate: \(app.labelSnapshot().sorted())")
    }
}

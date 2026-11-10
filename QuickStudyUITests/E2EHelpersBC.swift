import XCTest

extension QSTestCase {
    static let inputsDirectory = QSApp.fixturesDirectory.appendingPathComponent("Inputs", isDirectory: true)

    func fixtureText(_ name: String) -> String {
        (try? String(contentsOf: Self.inputsDirectory.appendingPathComponent(name), encoding: .utf8)) ?? ""
    }

    /// First button with this label that is actually on top (the Library tiles stay in the tree under the half sheet).
    func hittableButton(_ label: String) -> XCUIElement {
        let matches = app.buttons.matching(NSPredicate(format: "label == %@", label)).allElementsBoundByIndex
        return matches.first(where: { $0.isHittable }) ?? app.buttons[label].firstMatch
    }

    func openLibrary() {
        app.tapTab("Library")
        XCTAssertTrue(createButton.waitForExistence(timeout: QSApp.uiTimeout), "No floating create button")
    }

    /// The floating +. Only call from Library: the Save sheet's segmented control also has a "New Set" button.
    var createButton: XCUIElement { app.buttons["New Set"].firstMatch }

    enum Source {
        static let photo = "Choose Photo, From your photo library"
        static let pdf = "Choose PDF, From Files"
        static let paste = "Paste Text, From Notes, Safari or any app"
    }

    func openNewSetSheet(_ id: String) {
        openLibrary()
        createButton.tap()
        XCTAssertTrue(app.navigationBars["New Set"].waitForExistence(timeout: QSApp.uiTimeout),
                      "\(id): New Set sheet did not open. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 0.8)
    }

    /// Consent is asked after the source is picked and read, so it can arrive at any point before drafting starts.
    /// Tests only ever decline: accepting would send a real draft to the hosted server.
    @discardableResult
    func declineConsentIfAsked(_ id: String, wait: TimeInterval = 3) -> Bool {
        let notNow = app.buttons["Not Now"]
        guard notNow.waitForExistence(timeout: wait) else { return false }
        shot(id, "consent-sheet")
        note(id, "consent sheet shown, declined with Not Now")
        notNow.tap()
        Thread.sleep(forTimeInterval: 1.2)
        return true
    }

    func chooseSource(_ id: String, label: String) {
        openNewSetSheet(id)
        shot(id, "new-set-sheet")
        let target = hittableButton(label)
        XCTAssertTrue(target.waitForExistence(timeout: 4), "\(id): no '\(label)' in New Set sheet")
        target.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    func typeIntoPasteSheet(_ id: String, text: String) {
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: QSApp.uiTimeout), "\(id): no paste editor")
        editor.tap()
        editor.typeText(text)
    }

    /// The toolbar checkmark on the Paste Text sheet. Its accessibility label is "Draft Cards".
    var draftCardsButton: XCUIElement { app.navigationBars["Paste Text"].buttons["Draft Cards"] }

    func tapDraftCards(_ id: String) {
        XCTAssertTrue(draftCardsButton.waitForExistence(timeout: 5), "\(id): no Draft Cards checkmark")
        XCTAssertTrue(draftCardsButton.isEnabled, "\(id): Draft Cards disabled")
        draftCardsButton.tap()
    }

    static let failureTitles = [
        "Something went wrong", "We couldn\u{2019}t read this", "We couldn't read this", "Free generations used",
        "On-device AI isn't ready", "We couldn't open this PDF", "We couldn\u{2019}t open this PDF"
    ]

    enum GenerationOutcome: Equatable {
        case ready
        case failure(String)
        case timedOut
    }

    /// The status card's text is one combined accessibility element, "<title>, <detail>", and its type varies, so
    /// these match any element.
    private func statusText(beginningWith prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    var cancelDraftingButton: XCUIElement { app.buttons["Cancel drafting"] }
    var reviewCardButton: XCUIElement { app.buttons["Review"] }
    var dismissFailureButton: XCUIElement { app.buttons["Dismiss"] }
    var draftingCard: XCUIElement { statusText(beginningWith: "Drafting ") }
    var readyCard: XCUIElement { app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS ' is ready'")).firstMatch }

    var isDrafting: Bool { cancelDraftingButton.exists }

    func failureCard(_ title: String) -> XCUIElement { statusText(beginningWith: title) }

    private func visibleFailureTitle() -> String? {
        guard dismissFailureButton.exists else { return nil }
        return Self.failureTitles.first { failureCard($0).exists } ?? "unrecognised failure title"
    }

    /// Waits on the Library status card until the draft is ready or has failed, declining cloud consent if it is asked.
    func awaitGenerationOutcome(_ id: String, timeout: TimeInterval = QSApp.generationTimeout) -> (GenerationOutcome, TimeInterval) {
        let start = Date()
        var sampled = false
        while Date().timeIntervalSince(start) < timeout {
            if app.buttons["Not Now"].exists { declineConsentIfAsked(id, wait: 0.5) }
            if reviewCardButton.exists, readyCard.exists {
                return (.ready, Date().timeIntervalSince(start))
            }
            if let title = visibleFailureTitle() {
                return (.failure(title), Date().timeIntervalSince(start))
            }
            if !sampled, isDrafting {
                sampled = true
                shot(id, "drafting")
                dump(id, "drafting")
                note(id, "Drafting labels: \(app.labelSnapshot().sorted())")
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return (.timedOut, Date().timeIntervalSince(start))
    }

    func waitForDrafting(_ id: String, timeout: TimeInterval = 40) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if isDrafting { return true }
            if app.buttons["Not Now"].exists { declineConsentIfAsked(id, wait: 0.5) }
            Thread.sleep(forTimeInterval: 0.3)
        }
        return false
    }

    var reviewCardsNavBar: XCUIElement { app.navigationBars["Review Cards"] }
    var saveCardsButton: XCUIElement { app.buttons["Save Cards"] }

    /// Taps Review on the status card and waits for the Review Cards sheet.
    func tapReviewCard(_ id: String) {
        XCTAssertTrue(reviewCardButton.waitForExistence(timeout: QSApp.uiTimeout), "\(id): no Review button on the status card")
        reviewCardButton.tap()
        XCTAssertTrue(reviewCardsNavBar.waitForExistence(timeout: QSApp.uiTimeout), "\(id): Review Cards not reached. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 0.8)
    }

    func saveSheetNavBar(cards: Int) -> XCUIElement {
        app.navigationBars[cards == 1 ? "Save 1 Card" : "Save \(cards) Cards"]
    }

    /// Opens the Save sheet from Review Cards. The sheet's title carries the card count.
    func openSaveSheet(_ id: String, cards: Int) {
        XCTAssertTrue(saveCardsButton.waitForExistence(timeout: 5), "\(id): no Save Cards checkmark")
        saveCardsButton.tap()
        XCTAssertTrue(saveSheetNavBar(cards: cards).waitForExistence(timeout: QSApp.uiTimeout),
                      "\(id): Save sheet titled for \(cards) cards not shown. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 0.8)
    }

    /// The Save sheet's toolbar checkmark, scoped because Review Cards stays in the tree beneath it.
    func confirmSave(cards: Int) {
        let confirm = saveSheetNavBar(cards: cards).buttons["Save"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "No Save checkmark on the Save sheet")
        XCTAssertTrue(confirm.isEnabled, "Save checkmark disabled")
        confirm.tap()
    }

    /// Saves the open Review Cards draft as a new set, for flows where the drafted card count is not fixed.
    func saveDraftAsNewSet(_ id: String) {
        XCTAssertTrue(saveCardsButton.waitForExistence(timeout: 5), "\(id): no Save Cards checkmark")
        saveCardsButton.tap()
        let bar = app.navigationBars.matching(NSPredicate(format: "identifier BEGINSWITH 'Save '")).firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: QSApp.uiTimeout), "\(id): Save sheet not shown. Labels: \(app.labelSnapshot().sorted())")
        Thread.sleep(forTimeInterval: 0.8)
        note(id, "save sheet: \(bar.identifier)")
        bar.buttons["Save"].tap()
    }

    /// Long-presses the ready status card, opens Discard Draft and returns the confirmation alert.
    func openDiscardAlert(_ id: String) -> XCUIElement {
        XCTAssertTrue(readyCard.waitForExistence(timeout: 8), "\(id): no ready status card")
        readyCard.press(forDuration: 1.2)
        let discard = app.buttons["Discard Draft"]
        XCTAssertTrue(discard.waitForExistence(timeout: 4), "\(id): no Discard Draft in the card's menu. Labels: \(app.labelSnapshot().sorted())")
        shot(id, "card-context-menu")
        discard.tap()
        let alert = app.alerts["Discard Draft?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 4), "\(id): no Discard Draft? alert")
        return alert
    }

    var addToExistingSegment: XCUIElement { app.segmentedControls.buttons["Add to Existing"] }

    /// Swipes a Review Cards row. A long swipe deletes outright; a short one leaves the Delete action to tap.
    func deleteCard(_ row: XCUIElement) {
        row.swipeLeft()
        let delete = app.buttons["Delete"]
        if delete.waitForExistence(timeout: 1.5), delete.isHittable { delete.tap() }
        Thread.sleep(forTimeInterval: 1)
    }

    static let filesPickerBundleID = "com.apple.DocumentManagerUICore.Service"

    /// The Files picker is hosted out of process and its grid items are not exposed, so files are tapped by position.
    /// It reopens in the last folder used; this handles both that and a first open.
    func pickFile(_ id: String, named name: String) {
        let picker = XCUIApplication(bundleIdentifier: Self.filesPickerBundleID)
        XCTAssertTrue(picker.buttons["Browse"].waitForExistence(timeout: 10) || picker.buttons["Back"].waitForExistence(timeout: 2),
                      "\(id): Files picker did not open")
        Thread.sleep(forTimeInterval: 1)
        let inFolder = picker.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS 'Title: QuickStudy Fixtures'")).firstMatch
        if !inFolder.exists {
            for _ in 0..<5 where picker.buttons["Back"].exists && picker.buttons["Back"].isEnabled {
                picker.buttons["Back"].tap()
                Thread.sleep(forTimeInterval: 1)
            }
            if picker.buttons["Browse"].exists { picker.buttons["Browse"].tap() }
            Thread.sleep(forTimeInterval: 1.5)
            picker.coordinate(withNormalizedOffset: CGVector(dx: 0.30, dy: 0.353)).tap()
            Thread.sleep(forTimeInterval: 1.5)
            picker.coordinate(withNormalizedOffset: CGVector(dx: 0.18, dy: 0.28)).tap()
            Thread.sleep(forTimeInterval: 1.5)
        }
        shot(id, "picker-folder")
        let positions: [String: CGVector] = [
            "corrupt.pdf": CGVector(dx: 0.176, dy: 0.30),
            "large.pdf": CGVector(dx: 0.823, dy: 0.30),
            "small.pdf": CGVector(dx: 0.823, dy: 0.52)
        ]
        guard let position = positions[name] else {
            XCTFail("\(id): no known position for \(name)")
            return
        }
        picker.coordinate(withNormalizedOffset: position).tap()
    }

    /// PHPicker content is not queryable; the staged text page is the first tile.
    func pickFirstPhoto(_ id: String) {
        Thread.sleep(forTimeInterval: 3)
        shot(id, "photo-picker")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.235)).tap()
    }

    /// Home, 2 s, activate, then checks the app is foreground and not blank. Unlike the LC it does not compare labels,
    /// because the status card's text changes every second.
    func softLifecycle(_ id: String, name: String) {
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        app.activate()
        _ = app.wait(for: .runningForeground, timeout: QSApp.uiTimeout)
        Thread.sleep(forTimeInterval: 1)
        shot(id, name)
        dump(id, name)
        XCTAssertEqual(app.state, .runningForeground, "\(id): app not foreground after Home/activate")
        XCTAssertFalse(BlankScreenCheck.evaluate(app: app).isBlank, "\(id): blank after Home/activate (\(name))")
    }
}

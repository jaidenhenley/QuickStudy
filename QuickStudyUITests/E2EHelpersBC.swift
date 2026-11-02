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
        XCTAssertTrue(app.buttons["New set"].waitForExistence(timeout: QSApp.uiTimeout), "No floating create button")
    }

    func openNewSetSheet(_ id: String) {
        openLibrary()
        app.buttons["New set"].tap()
        XCTAssertTrue(app.staticTexts["Capture a page and cards draft automatically."].waitForExistence(timeout: QSApp.uiTimeout),
                      "\(id): New set sheet did not open")
        Thread.sleep(forTimeInterval: 0.8)
    }

    /// Declines when the first-import cloud consent sheet appears. Returns whether it appeared.
    @discardableResult
    func declineConsentIfAsked(_ id: String, wait: TimeInterval = 3) -> Bool {
        let notNow = app.buttons["Not now"]
        guard notNow.waitForExistence(timeout: wait) else { return false }
        shot(id, "consent-sheet")
        note(id, "consent sheet shown, declined with Not now")
        notNow.tap()
        Thread.sleep(forTimeInterval: 1.2)
        return true
    }

    func chooseSource(_ id: String, label: String, declineConsent: Bool = true) {
        openNewSetSheet(id)
        shot(id, "new-set-sheet")
        let target = hittableButton(label)
        XCTAssertTrue(target.waitForExistence(timeout: 4), "\(id): no '\(label)' in New set sheet")
        target.tap()
        Thread.sleep(forTimeInterval: 1.5)
        if declineConsent { declineConsentIfAsked(id) }
    }

    /// Types text into the paste editor, dismisses the keyboard and returns the Generate button.
    func typeIntoPasteSheet(_ id: String, text: String) {
        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: QSApp.uiTimeout), "\(id): no paste editor")
        editor.tap()
        editor.typeText(text)
    }

    func dismissKeyboardOnSheet() {
        if app.keyboards.count > 0 { app.swipeDown() }
        Thread.sleep(forTimeInterval: 0.8)
    }

    static let failureTitles = [
        "Something went wrong", "We couldn\u{2019}t read this", "We couldn't read this", "Free generations used",
        "On-device AI isn't ready", "On-device AI isn\u{2019}t ready"
    ]

    enum GenerationOutcome: Equatable {
        case scanPreview
        case reviewDrafts
        case failure(String)
        case timedOut
    }

    /// Waits for Generating to finish and reports where the app landed. `elapsed` is seconds since the call.
    func awaitGenerationOutcome(_ id: String, timeout: TimeInterval = QSApp.generationTimeout, sampleGenerating: Bool = true) -> (GenerationOutcome, TimeInterval) {
        let start = Date()
        var sampled = false
        var engineSeen = false
        while Date().timeIntervalSince(start) < timeout {
            if button(beginningWith: "Review ").exists, app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'CARD '")).count > 0 {
                return (.scanPreview, Date().timeIntervalSince(start))
            }
            if app.navigationBars["Draft cards"].exists || button(beginningWith: "Save ").exists {
                return (.reviewDrafts, Date().timeIntervalSince(start))
            }
            for title in Self.failureTitles where app.staticTexts[title].exists {
                return (.failure(title), Date().timeIntervalSince(start))
            }
            if sampleGenerating, !sampled, generatingVisible {
                sampled = true
                shot(id, "generating")
                dump(id, "generating")
                note(id, "Generating labels: \(app.labelSnapshot().sorted())")
            }
            if !engineSeen {
                for engine in ["Drafting on this iPhone", "Drafting with Private Cloud Compute", "Drafting in the cloud", "Drafting with your API key"]
                where app.element(labelContaining: engine).exists {
                    engineSeen = true
                    note(id, "engine line: \(engine) at \(Int(Date().timeIntervalSince(start)))s")
                    shot(id, "drafting")
                    break
                }
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return (.timedOut, Date().timeIntervalSince(start))
    }

    /// Pages through a draft that opened on Scan Preview and lands on Review drafts.
    func continueToReviewDrafts(_ id: String) {
        let review = button(beginningWith: "Review ")
        if review.waitForExistence(timeout: 3), !button(beginningWith: "Save ").exists {
            review.tap()
        }
        XCTAssertTrue(button(beginningWith: "Save ").waitForExistence(timeout: QSApp.uiTimeout), "\(id): Review drafts not reached")
    }

    var generatingVisible: Bool {
        app.element(labelContaining: "Reading page").exists || app.element(labelContaining: "Drafting cards").exists
    }

    func waitForGenerating(timeout: TimeInterval = 40) -> Bool {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end {
            if generatingVisible { return true }
            Thread.sleep(forTimeInterval: 0.3)
        }
        return false
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
    /// because Generating's text changes every second.
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

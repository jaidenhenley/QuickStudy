import XCTest

extension QSTestCase {
    func shot(_ id: String, _ name: String) {
        app.screenshot(named: "\(id)-\(name)", in: self)
    }

    func dump(_ id: String, _ name: String) {
        app.dumpHierarchy(named: "\(id)-\(name)", in: self)
    }

    func note(_ id: String, _ text: String) {
        add(XCTAttachment(string: text))
        let url = Evidence.directory.appendingPathComponent("\(id)-notes.txt")
        let existing = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        try? (existing + text + "\n").write(to: url, atomically: true, encoding: .utf8)
    }

    func button(beginningWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    func text(containing fragment: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", fragment)).firstMatch
    }

    @discardableResult
    func tapButton(beginningWith prefix: String, timeout: TimeInterval = QSApp.uiTimeout) -> Bool {
        let target = button(beginningWith: prefix)
        guard target.waitForExistence(timeout: timeout) else {
            XCTFail("No button beginning '\(prefix)' within \(timeout)s")
            return false
        }
        target.tap()
        return true
    }

    struct FrameWatch {
        let frames: Int
        let blankFrames: Int
        let minDeviation: Double
    }

    /// Screenshots back to back for `seconds`; any frame that is flat colour counts as blank (a white-screen flash).
    func watchFrames(_ id: String, _ name: String, seconds: TimeInterval) -> FrameWatch {
        let end = Date().addingTimeInterval(seconds)
        var frames = 0, blank = 0
        var minimum = Double.greatestFiniteMagnitude
        while Date() < end {
            let shot = XCUIScreen.main.screenshot()
            let deviation = BlankScreenCheck.pixelStandardDeviation(of: shot.image.cgImage)
            frames += 1
            minimum = min(minimum, deviation)
            if deviation < BlankScreenCheck.minimumPixelStandardDeviation {
                blank += 1
                let attachment = XCTAttachment(screenshot: shot)
                attachment.name = "\(id)-\(name)-blankframe-\(blank)"
                attachment.lifetime = .keepAlways
                add(attachment)
                try? shot.pngRepresentation.write(
                    to: Evidence.directory.appendingPathComponent(Evidence.fileName("\(id)-\(name)-blankframe-\(blank)") + ".png"))
            }
        }
        note(id, "\(name): \(frames) frames, \(blank) blank, min stddev \(String(format: "%.1f", minimum))")
        return FrameWatch(frames: frames, blankFrames: blank, minDeviation: minimum)
    }

    func advanceOnboarding(through labels: [String] = ["Get Started", "Continue", "Continue"]) {
        for label in labels {
            guard app.buttons[label].waitForExistence(timeout: QSApp.uiTimeout) else {
                XCTFail("Onboarding button '\(label)' missing")
                return
            }
            app.buttons[label].tap()
            Thread.sleep(forTimeInterval: 0.8)
        }
    }
}

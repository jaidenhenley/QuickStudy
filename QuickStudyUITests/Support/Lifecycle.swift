import XCTest

extension XCUIApplication {
    /// Labels of the visible, labelled controls and texts; used to compare screens before and after a lifecycle event.
    func labelSnapshot() -> Set<String> {
        var labels = Set<String>()
        for kind in [XCUIElement.ElementType.staticText, .button, .textField, .textView, .switch] {
            let query = descendants(matching: kind)
            for index in 0..<min(query.count, 60) {
                let element = query.element(boundBy: index)
                if element.exists, !element.label.isEmpty { labels.insert(element.label) }
            }
        }
        return labels
    }

    /// The script's LC: Home, wait 2 s, activate, same screen, not blank. `rotate` also does a landscape round trip.
    @discardableResult
    func lifecycleCheckpoint(
        _ id: String,
        in test: XCTestCase,
        rotate: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let before = labelSnapshot()
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        activate()
        _ = wait(for: .runningForeground, timeout: QSApp.uiTimeout)
        Thread.sleep(forTimeInterval: 1)
        var ok = true
        let report = BlankScreenCheck.evaluate(app: self)
        if report.isBlank {
            screenshot(named: "\(id)-LC-BLANK", in: test)
            dumpHierarchy(named: "\(id)-LC-BLANK", in: test)
            XCTFail("\(id) LC: blank after Home/activate. \(report.summary)", file: file, line: line)
            ok = false
        }
        let after = labelSnapshot()
        let kept = before.intersection(after).count
        if !before.isEmpty, Double(kept) / Double(before.count) < 0.7 {
            screenshot(named: "\(id)-LC-CHANGED", in: test)
            dumpHierarchy(named: "\(id)-LC-CHANGED", in: test)
            XCTFail("\(id) LC: screen changed. Lost \(before.subtracting(after).sorted())", file: file, line: line)
            ok = false
        }
        if rotate {
            XCUIDevice.shared.orientation = .landscapeLeft
            Thread.sleep(forTimeInterval: 1.5)
            screenshot(named: "\(id)-LC-landscape", in: test)
            XCUIDevice.shared.orientation = .portrait
            Thread.sleep(forTimeInterval: 1.5)
            if BlankScreenCheck.evaluate(app: self).isBlank {
                screenshot(named: "\(id)-LC-rotate-BLANK", in: test)
                XCTFail("\(id) LC: blank after rotation", file: file, line: line)
                ok = false
            }
        }
        return ok
    }
}

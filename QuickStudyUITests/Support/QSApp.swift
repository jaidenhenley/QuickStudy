import XCTest

enum QSApp {
    static let bundleID = "com.henley.jaiden.QuickStudy"
    static let resetArgument = "-QSResetInstall"

    static let launchTimeout: TimeInterval = 20
    static let uiTimeout: TimeInterval = 8
    static let generationTimeout: TimeInterval = 120

    /// Combines the arguments and environment of every state. `extraArguments` and
    /// `environment` are applied last so a test can override a state's value.
    @discardableResult
    static func launch(
        _ states: SeedState...,
        extraArguments: [String] = [],
        environment: [String: String] = [:]
    ) -> XCUIApplication {
        launch(states: states, extraArguments: extraArguments, environment: environment)
    }

    @discardableResult
    static func launch(
        states: [SeedState],
        extraArguments: [String] = [],
        environment: [String: String] = [:]
    ) -> XCUIApplication {
        if states.contains(where: \.needsPurchase) {
            do {
                try StoreKitTesting.purchase()
            } catch {
                XCTFail("StoreKit purchase failed: \(error)")
            }
        }
        let app = XCUIApplication(bundleIdentifier: bundleID)
        app.launchArguments = states.flatMap(\.launchArguments) + extraArguments
        var merged = states.reduce(into: [String: String]()) { $0.merge($1.environment) { _, new in new } }
        merged.merge(environment) { _, new in new }
        app.launchEnvironment = merged
        app.launch()
        return app
    }

    static var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static var fixturesDirectory: URL {
        repositoryRoot.appendingPathComponent("QuickStudyUITests/Fixtures", isDirectory: true)
    }

    static var storeKitConfiguration: URL {
        repositoryRoot.appendingPathComponent("QuickStudy/QuickStudy.storekit")
    }
}

extension XCUIApplication {
    /// Terminates and launches again with the same environment, dropping `-QSResetInstall`
    /// so on-disk state survives. Use this to test persistence across launches.
    func relaunchKeepingState() {
        terminate()
        launchArguments.removeAll { $0 == QSApp.resetArgument }
        launch()
    }

    @discardableResult
    func screenshot(named name: String, in test: XCTestCase? = nil) -> URL? {
        Evidence.screenshot(name, app: self, in: test)
    }

    @discardableResult
    func dumpHierarchy(named name: String, in test: XCTestCase? = nil) -> URL? {
        Evidence.hierarchy(name, app: self, in: test)
    }

    /// Fails and saves a screenshot and hierarchy when the screen has too few labelled
    /// elements or is a flat colour. Waits up to `timeout` for content to appear first.
    @discardableResult
    func assertNotBlank(
        _ name: String,
        in test: XCTestCase? = nil,
        timeout: TimeInterval = QSApp.uiTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> BlankScreenCheck.Report {
        var report = BlankScreenCheck.evaluate(app: self)
        let deadline = Date().addingTimeInterval(timeout)
        while report.isBlank, Date() < deadline {
            Thread.sleep(forTimeInterval: 0.5)
            report = BlankScreenCheck.evaluate(app: self)
        }
        if report.isBlank || state != .runningForeground {
            screenshot(named: name + "-BLANK", in: test)
            dumpHierarchy(named: name + "-BLANK", in: test)
            XCTFail("Blank screen at \(name): \(report.summary), state: \(state.rawValue)", file: file, line: line)
        }
        return report
    }

    /// First element of any type whose label (or identifier) equals `text`.
    func element(labelled text: String) -> XCUIElement {
        let predicate = NSPredicate(format: "label == %@ OR identifier == %@", text, text)
        return descendants(matching: .any).matching(predicate).firstMatch
    }

    func element(labelContaining text: String) -> XCUIElement {
        descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func button(_ label: String) -> XCUIElement {
        buttons.matching(NSPredicate(format: "label == %@ OR identifier == %@", label, label)).firstMatch
    }

    @discardableResult
    func tap(
        _ label: String,
        timeout: TimeInterval = QSApp.uiTimeout,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Bool {
        let target = element(labelled: label)
        guard target.waitForExistence(timeout: timeout) else {
            XCTFail("No element labelled '\(label)' within \(timeout)s", file: file, line: line)
            return false
        }
        target.tap()
        return true
    }

    func tapTab(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = tabBars.buttons[title]
        XCTAssertTrue(tab.waitForExistence(timeout: QSApp.uiTimeout), "Tab '\(title)' missing", file: file, line: line)
        tab.tap()
    }

    func waitForAny(_ labels: [String], timeout: TimeInterval = QSApp.uiTimeout) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        repeat {
            for label in labels where element(labelled: label).exists { return label }
            Thread.sleep(forTimeInterval: 0.25)
        } while Date() < deadline
        return nil
    }
}

extension XCUIElement {
    @discardableResult
    func waitUntilGone(timeout: TimeInterval = QSApp.uiTimeout) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func waitUntilHittable(timeout: TimeInterval = QSApp.uiTimeout) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isHittable == true"), object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

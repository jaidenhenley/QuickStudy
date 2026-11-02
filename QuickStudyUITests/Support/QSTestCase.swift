import XCTest

class QSTestCase: XCTestCase {
    var app: XCUIApplication!
    var alertPolicy: SystemAlerts.Policy { .allow }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        installSystemAlertMonitor(alertPolicy)
    }

    override func tearDown() {
        StoreKitTesting.stopSession()
        XCUIDevice.shared.appearance = .light
        XCUIDevice.shared.orientation = .portrait
        if let run = testRun, run.totalFailureCount > 0, let app, app.state != .notRunning {
            let name = Evidence.fileName(name) + "-FAILED"
            Evidence.screenshot(name, app: app, in: self)
            Evidence.hierarchy(name, app: app, in: self)
        }
        super.tearDown()
    }

    @discardableResult
    func launch(
        _ states: SeedState...,
        extraArguments: [String] = [],
        environment: [String: String] = [:]
    ) -> XCUIApplication {
        app = QSApp.launch(states: states, extraArguments: extraArguments, environment: environment)
        return app
    }
}

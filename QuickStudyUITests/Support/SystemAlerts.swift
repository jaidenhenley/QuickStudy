import XCTest

enum SystemAlerts {
    enum Policy {
        case allow, deny
    }

    static let allowButtons = [
        "Allow", "Allow While Using App", "Allow Once", "Allow Paste", "Allow Full Access", "OK", "Continue"
    ]
    static let denyButtons = ["Don\u{2019}t Allow", "Don't Allow", "Cancel"]

    static var springboard: XCUIApplication {
        XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }

    /// Taps the matching button of a springboard-owned alert. Returns whether one was handled.
    /// Prefer this over interruption monitors when the test knows an alert is coming.
    @discardableResult
    static func handle(_ policy: Policy, timeout: TimeInterval = 5) -> Bool {
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: timeout) else { return false }
        let candidates = policy == .allow ? allowButtons : denyButtons
        for title in candidates {
            let button = alert.buttons[title]
            if button.exists {
                button.tap()
                return true
            }
        }
        return false
    }
}

extension XCTestCase {
    /// Installs a monitor that answers any system alert. It only fires when a test next
    /// interacts with the app, so alerts the test expects should use `SystemAlerts.handle`.
    @discardableResult
    func installSystemAlertMonitor(_ policy: SystemAlerts.Policy = .allow) -> NSObjectProtocol {
        addUIInterruptionMonitor(withDescription: "System alert (\(policy))") { alert in
            let titles = policy == .allow ? SystemAlerts.allowButtons : SystemAlerts.denyButtons
            for title in titles where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            return false
        }
    }
}

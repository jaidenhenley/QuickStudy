import XCTest

/// Does the scheme's StoreKit configuration apply without an SKTestSession in the runner?
/// Opens the paywall from the generations pill and records whether products load.
final class StoreKitSchemeTests: QSTestCase {
    func testPaywallProductsWithoutRunnerSession() {
        launch(.demoData)
        let pill = app.buttons.matching(NSPredicate(format: "label CONTAINS 'free generations'")).firstMatch
        XCTAssertTrue(pill.waitForExistence(timeout: 8), "No generations pill")
        pill.tap()
        Thread.sleep(forTimeInterval: 5)
        shot("SK-scheme", "paywall")
        dump("SK-scheme", "paywall")
        let labels = app.labelSnapshot().sorted()
        try? labels.joined(separator: "\n").write(
            to: Evidence.directory.appendingPathComponent("SK-scheme-labels.txt"), atomically: true, encoding: .utf8)
        let priced = labels.contains { $0.contains("4.99") || $0.contains("39.99") }
        add(XCTAttachment(string: "products priced: \(priced)"))
        XCTAssertTrue(priced, "No product prices on the paywall; the scheme StoreKit configuration did not apply. Labels: \(labels)")
    }
}

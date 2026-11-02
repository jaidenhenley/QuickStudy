import XCTest

/// Purchases made through StoreKitTesting outlive the test run on the simulator. Run this to
/// return the app to non-Pro: -only-testing:QuickStudyUITests/StoreKitResetTests
final class StoreKitResetTests: XCTestCase {
    func testClearTransactions() throws {
        try StoreKitTesting.startSession(clearTransactions: true)
        StoreKitTesting.stopSession()
    }
}

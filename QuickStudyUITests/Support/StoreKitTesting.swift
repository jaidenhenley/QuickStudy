import StoreKitTest
import XCTest

/// Drives the local QuickStudy.storekit configuration from the runner. The session must stay
/// alive for the whole test: StoreKit reverts to the App Store when it deallocates.
enum StoreKitTesting {
    enum Product: String {
        case monthly = "com.henley.jaiden.QuickStudy.pro.monthly"
        case yearly = "com.henley.jaiden.QuickStudy.pro.yearly"
    }

    private static var activeSession: SKTestSession?

    @discardableResult
    static func startSession(clearTransactions: Bool = true) throws -> SKTestSession {
        let session = try SKTestSession(contentsOf: QSApp.storeKitConfiguration)
        session.disableDialogs = true
        session.askToBuyEnabled = false
        if clearTransactions { session.clearTransactions() }
        activeSession = session
        return session
    }

    static func purchase(_ product: Product = .monthly) throws {
        let session = try activeSession ?? startSession()
        try session.buyProduct(productIdentifier: product.rawValue)
    }

    static func stopSession() {
        activeSession?.clearTransactions()
        activeSession = nil
    }
}

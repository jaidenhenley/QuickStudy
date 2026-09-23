//
//  StoreController.swift
//  QuickStudy
//

import Foundation
import StoreKit

@MainActor
@Observable
final class StoreController {
    private static let freeHostedUsedKey = "qs_hostedFreeGenerationUsed"
    private static let lastKnownProKey = "qs_lastKnownPro"
    private static let hostedRemainingKey = "qs_hostedRemaining"
    private static let hostedRemainingMonthKey = "qs_hostedRemainingMonth"
    private static let freshPurchaseWindow: TimeInterval = 600

    private(set) var activeTransaction: Transaction? = nil
    /// Sent to the server with every hosted generation; the server verifies it, not the app.
    private(set) var transactionJWS: String? = nil
    /// Only set while the subscription is in Billing Grace Period — the transaction JWS
    /// alone reads as expired then, and the server needs this to keep Pro working.
    private(set) var renewalInfoJWS: String? = nil
    private(set) var hostedRemaining: Int? = StoreController.storedHostedRemaining()
    private(set) var freeHostedGenerationUsed = UserDefaults.standard.bool(forKey: StoreController.freeHostedUsedKey)
    // deinit is nonisolated; the task is only ever assigned on the main actor and cancelled here.
    @ObservationIgnored nonisolated(unsafe) private var updates: Task<Void, Never>? = nil
    @ObservationIgnored private let analytics: AnalyticsRecorder

    var isPro: Bool { activeTransaction != nil }

    var isEligibleForHostedGeneration: Bool { transactionJWS != nil || !freeHostedGenerationUsed }

    /// Single source of truth for whether the next generation leaves this iPhone.
    /// `AIController` routes on it and the paste sheet's privacy promise depends on it —
    /// they must never disagree.
    var willUseHostedGeneration: Bool { isEligibleForHostedGeneration && HostedConsent.decision == .granted }

    init(analytics: AnalyticsRecorder) {
        self.analytics = analytics
    }

    deinit {
        updates?.cancel()
    }

    /// Started once by the app root rather than in `init`, so a discarded instance never
    /// holds a second `Transaction.updates` listener.
    func startObservingTransactions() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlement()
            }
        }
    }

    func refreshEntitlement() async {
        var current: (transaction: Transaction, jws: String, renewalInfo: String?)? = nil
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  ProProduct(rawValue: transaction.productID) != nil,
                  transaction.revocationDate == nil else { continue }
            var renewalInfo: String? = nil
            if let expiration = transaction.expirationDate, expiration <= Date() {
                guard let status = await transaction.subscriptionStatus,
                      status.state == .inGracePeriod,
                      case .verified = status.renewalInfo else { continue }
                renewalInfo = status.renewalInfo.jwsRepresentation
            }
            current = (transaction, result.jwsRepresentation, renewalInfo)
        }
        activeTransaction = current?.transaction
        transactionJWS = current?.jws
        renewalInfoJWS = current?.renewalInfo
        if current == nil { storeHostedRemaining(nil) }
        noteProTransition(to: current?.transaction)
    }

    /// Transitions are measured against the last launch, not this instance's initial
    /// `false`, or every cold start of a subscriber would read as a new purchase.
    private func noteProTransition(to transaction: Transaction?) {
        let defaults = UserDefaults.standard
        let wasPro = defaults.bool(forKey: Self.lastKnownProKey)
        defaults.set(transaction != nil, forKey: Self.lastKnownProKey)
        guard !wasPro, let transaction else { return }

        if HostedConsent.decision == .declined { HostedConsent.reset() }
        if transaction.reason == .purchase,
           Date().timeIntervalSince(transaction.purchaseDate) < Self.freshPurchaseWindow {
            analytics.record(.purchaseCompleted)
        }
    }

    /// The server is the authority on the free hosted generation. When it says the
    /// allowance is spent — after a reinstall, say — local state has to agree or the
    /// app will keep trying an engine it can no longer use.
    func markFreeHostedGenerationUsed() {
        freeHostedGenerationUsed = true
        UserDefaults.standard.set(true, forKey: Self.freeHostedUsedKey)
    }

    func recordHostedGeneration(remaining: Int, usedFreeGeneration: Bool) {
        if usedFreeGeneration {
            markFreeHostedGenerationUsed()
        } else {
            storeHostedRemaining(remaining)
        }
    }

    private func storeHostedRemaining(_ remaining: Int?) {
        hostedRemaining = remaining
        let defaults = UserDefaults.standard
        if let remaining {
            defaults.set(remaining, forKey: Self.hostedRemainingKey)
            defaults.set(GenerationAllowance.monthStamp(for: Date()), forKey: Self.hostedRemainingMonthKey)
        } else {
            defaults.removeObject(forKey: Self.hostedRemainingKey)
            defaults.removeObject(forKey: Self.hostedRemainingMonthKey)
        }
    }

    /// The server's Pro quota is monthly, so last month's count is stale and not shown.
    private static func storedHostedRemaining(now: Date = Date()) -> Int? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: hostedRemainingKey) != nil,
              defaults.integer(forKey: hostedRemainingMonthKey) == GenerationAllowance.monthStamp(for: now) else { return nil }
        return defaults.integer(forKey: hostedRemainingKey)
    }
}

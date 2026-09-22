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

    private(set) var activeTransaction: Transaction? = nil
    /// Sent to the server with every hosted generation; the server verifies it, not the app.
    private(set) var transactionJWS: String? = nil
    private(set) var hostedRemaining: Int? = nil
    private(set) var freeHostedGenerationUsed = UserDefaults.standard.bool(forKey: StoreController.freeHostedUsedKey)
    // deinit is nonisolated; the task is only ever assigned in init and cancelled here.
    @ObservationIgnored nonisolated(unsafe) private var updates: Task<Void, Never>? = nil

    var isPro: Bool { activeTransaction != nil }

    init() {
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlement()
            }
        }
    }

    deinit {
        updates?.cancel()
    }

    func refreshEntitlement() async {
        var current: (transaction: Transaction, jws: String)? = nil
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  ProProduct(rawValue: transaction.productID) != nil,
                  transaction.revocationDate == nil else { continue }
            if let expiration = transaction.expirationDate, expiration <= Date() { continue }
            current = (transaction, result.jwsRepresentation)
        }
        activeTransaction = current?.transaction
        transactionJWS = current?.jws
        if current == nil { hostedRemaining = nil }
    }

    /// The server is the authority on the free hosted generation. When it says the
    /// allowance is spent — after a reinstall, say — local state has to agree or the
    /// app will keep trying an engine it can no longer use.
    func markFreeHostedGenerationUsed() {
        freeHostedGenerationUsed = true
        UserDefaults.standard.set(true, forKey: Self.freeHostedUsedKey)
    }

    func recordHostedGeneration(remaining: Int, usedFreeGeneration: Bool) {
        hostedRemaining = remaining
        if usedFreeGeneration {
            freeHostedGenerationUsed = true
            UserDefaults.standard.set(true, forKey: Self.freeHostedUsedKey)
        }
    }
}

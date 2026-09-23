//
//  AIController.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/23/26.
//

import SwiftUI

enum CardGenerationMode: String, Codable, Hashable {
    case onDevice, externalAPI
}

enum AIController {
    @MainActor
    static func makeGenerator(
        settings: AISettings,
        store: StoreController,
        progress: GenerationProgress? = nil
    ) throws -> any CardGenerating {
        switch settings.mode {
        case .onDevice:
            if let hosted = hostedEngine(settings: settings, store: store) { return hosted }
            return try makeOnDeviceGenerator(progress: progress)

        case .externalAPI:
            guard let key = settings.apiKey, !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw CardGenerationError.missingAPIKey
            }

            guard let endpoint = settings.endpoint else {
                throw CardGenerationError.invalidEndpoint
            }

            let defaultModel: String
            switch settings.apiFormat {
            case .openAI:
                defaultModel = "gpt-4.1-mini"
            case .anthropic:
                defaultModel = "claude-sonnet-4-20250514"
            }

            return APICardGenerationEngine(
                endpoint: endpoint,
                model: settings.modelName ?? defaultModel,
                apiKey: key,
                apiFormat: settings.apiFormat
            )
        }
    }

    @MainActor
    static func makeOnDeviceGenerator(progress: GenerationProgress? = nil) throws -> any CardGenerating {
        #if canImport(FoundationModels)
        return OnDeviceCardGenerationEngine(progress: progress)
        #else
        throw CardGenerationError.deviceNotEligible
        #endif
    }

    static var isOnDeviceModelAvailable: Bool {
        #if canImport(FoundationModels)
        return OnDeviceModelAvailability.isAvailable
        #else
        return false
        #endif
    }

    /// True when the next generation would go to QuickStudy's server but the user has
    /// not yet been asked. The import flow asks before calling `makeGenerator`.
    @MainActor
    static func requiresHostedConsent(settings: AISettings, store: StoreController) -> Bool {
        settings.mode == .onDevice && store.isEligibleForHostedGeneration && HostedConsent.decision == nil
    }

    /// Whether a failed hosted attempt should be redrafted on this iPhone. Free users fall
    /// back on anything but oversized input; Pro users only when the server can't serve
    /// them right now, so a real outage still surfaces instead of quietly downgrading.
    static func fallsBackOnDevice(after error: Error, isPro: Bool) -> Bool {
        guard !(error is CancellationError), let error = error as? CardGenerationError else { return !isPro }
        switch error {
        case .hostedInputTooLarge:
            return isPro
        case .networkError, .hostedQuotaExhausted, .notSubscribed:
            return true
        default:
            return !isPro
        }
    }

    /// Failures a retry with the same free hosted generation cannot get past.
    static func spendsFreeHostedGeneration(_ error: Error) -> Bool {
        switch error as? CardGenerationError {
        case .notSubscribed, .attestationUnavailable:
            return true
        default:
            return false
        }
    }

    /// Pro always generates on the server. Everyone else gets one free hosted generation —
    /// it is the first one they ever run, so the app opens on its best output rather than
    /// its weakest. Neither ever sends without the user's consent.
    @MainActor
    private static func hostedEngine(settings: AISettings, store: StoreController) -> HostedCardGenerationEngine? {
        guard store.willUseHostedGeneration else { return nil }
        let transaction = store.transactionJWS
        return HostedCardGenerationEngine(
            api: .configured(),
            transaction: transaction,
            renewalInfo: transaction == nil ? nil : store.renewalInfoJWS
        ) { remaining in
            store.recordHostedGeneration(remaining: remaining, usedFreeGeneration: transaction == nil)
        }
    }
}

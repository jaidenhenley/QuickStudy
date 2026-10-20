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
    /// Private Cloud Compute drafts in 6,000-character requests, so a long document would
    /// spend Apple's daily quota fast. Pro sends those to QuickStudy's server instead.
    static let proPrivateCloudLimit = 12_000

    /// Engines in the order they are tried. A later one runs only when `movesOn` allows it
    /// after the one before it fails.
    @MainActor
    static func makeGenerators(
        settings: AISettings,
        store: StoreController,
        sourceLength: Int,
        progress: GenerationProgress? = nil
    ) throws -> [any CardGenerating] {
        try plan(settings: settings, store: store, sourceLength: sourceLength).compactMap { engine in
            switch engine {
            case .privateCloud: PrivateCloud.makeEngine(progress: progress)
            case .cloud: hostedEngine(store: store)
            case .onDevice: try makeOnDeviceGenerator(progress: progress)
            case .externalAPI: try makeAPIGenerator(settings: settings)
            }
        }
    }

    /// The order `makeGenerators` builds, without building anything, so the UI can name
    /// where a draft will run.
    @MainActor
    static func plan(settings: AISettings, store: StoreController, sourceLength: Int) -> [GenerationProvenance.Engine] {
        plan(
            for: DraftingConditions(
                mode: settings.mode,
                consent: HostedConsent.decision,
                isPro: store.isPro,
                freeHostedGenerationUnused: !store.freeHostedGenerationUsed,
                hasOnDeviceModel: isOnDeviceModelAvailable,
                privateCloudReady: isPrivateCloudReady
            ),
            sourceLength: sourceLength
        )
    }

    static func plan(for conditions: DraftingConditions, sourceLength: Int) -> [GenerationProvenance.Engine] {
        guard conditions.mode == .onDevice else { return [.externalAPI] }

        let consented = conditions.consent == .granted
        var plan: [GenerationProvenance.Engine] = []
        if consented, conditions.privateCloudReady,
           privateCloudTakes(sourceLength: sourceLength, isPro: conditions.isPro) {
            plan.append(.privateCloud)
        }
        // Pro uses the server whenever PCC doesn't take the draft. The free hosted
        // generation exists to open on the best output, and PCC already gives that, so
        // it is kept for iPhones without PCC.
        let usesServer = consented
            && (conditions.isPro || (conditions.freeHostedGenerationUnused && !conditions.privateCloudReady))
        // An oversized document still goes to the server when nothing on this iPhone
        // can draft it, so the user sees the server's "too long" message.
        let fitsServer = sourceLength <= HostedCardGenerationEngine.maxInputLength
        if usesServer, fitsServer || !conditions.hasOnDeviceModel {
            plan.append(.cloud)
        }
        if conditions.hasOnDeviceModel || plan.isEmpty {
            plan.append(.onDevice)
        }
        return plan
    }

    /// Free users always prefer Private Cloud Compute. Pro uses it for short documents, and
    /// for anything too long for the server, which nothing else could draft in one pass.
    static func privateCloudTakes(sourceLength: Int, isPro: Bool) -> Bool {
        guard isPro else { return true }
        return sourceLength <= proPrivateCloudLimit || sourceLength > HostedCardGenerationEngine.maxInputLength
    }

    /// Private Cloud Compute always hands off: whatever follows it is the user's next-best
    /// engine. The server hands off only by `fallsBackOnDevice`. Nothing follows the
    /// on-device model or the user's own API.
    static func movesOn(after error: Error, from engine: GenerationProvenance.Engine, isPro: Bool) -> Bool {
        if error is CancellationError { return false }
        switch engine {
        case .privateCloud: return true
        case .cloud: return fallsBackOnDevice(after: error, isPro: isPro)
        case .onDevice, .externalAPI: return false
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

    @MainActor
    static var isOnDeviceModelAvailable: Bool {
        #if canImport(FoundationModels)
        return OnDeviceModelAvailability.isAvailable
        #else
        return false
        #endif
    }

    /// True when the next generation would leave this iPhone, for QuickStudy's server or
    /// Private Cloud Compute, but the user has not yet been asked. The import flow asks
    /// before calling `makeGenerators`.
    @MainActor
    static func requiresHostedConsent(settings: AISettings, store: StoreController) -> Bool {
        settings.mode == .onDevice
            && HostedConsent.decision == nil
            && (store.isEligibleForHostedGeneration || isPrivateCloudReady)
    }

    /// Whether the next draft could run on Private Cloud Compute, so the import flow can
    /// warm it while the camera or picker is open.
    @MainActor
    static func mayUsePrivateCloud(settings: AISettings) -> Bool {
        settings.mode == .onDevice && HostedConsent.decision == .granted && isPrivateCloudReady
    }

    /// Whether a failed hosted attempt should be redrafted on this iPhone. Free users fall
    /// back on anything but oversized input; Pro users only when the server can't serve
    /// them right now, so a real outage still surfaces instead of quietly downgrading.
    static func fallsBackOnDevice(after error: Error, isPro: Bool) -> Bool {
        if error is CancellationError { return false }
        guard let error = error as? CardGenerationError else { return !isPro }
        switch error {
        case .hostedInputTooLarge:
            return isPro
        case .networkError, .hostedQuotaExhausted, .notSubscribed, .freeHostedGenerationUsed:
            return true
        default:
            return !isPro
        }
    }

    /// Failures a retry with the same free hosted generation cannot get past.
    static func spendsFreeHostedGeneration(_ error: Error) -> Bool {
        switch error as? CardGenerationError {
        case .notSubscribed, .freeHostedGenerationUsed, .attestationUnavailable:
            return true
        default:
            return false
        }
    }

    @MainActor
    private static var isPrivateCloudReady: Bool {
        if case .ready = PrivateCloud.status { return true }
        return false
    }

    @MainActor
    private static func makeAPIGenerator(settings: AISettings) throws -> any CardGenerating {
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

    @MainActor
    private static func hostedEngine(store: StoreController) -> HostedCardGenerationEngine {
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

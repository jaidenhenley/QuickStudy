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
            return OnDeviceCardGenerationEngine(progress: progress)

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

    /// Pro always generates on the server. Everyone else gets one free hosted generation —
    /// it is the first one they ever run, so the app opens on its best output rather than
    /// its weakest.
    @MainActor
    private static func hostedEngine(settings: AISettings, store: StoreController) -> HostedCardGenerationEngine? {
        let transaction = store.transactionJWS
        guard transaction != nil || !store.freeHostedGenerationUsed else { return nil }
        return HostedCardGenerationEngine(api: .configured(), transaction: transaction) { remaining in
            store.recordHostedGeneration(remaining: remaining, usedFreeGeneration: transaction == nil)
        }
    }
}

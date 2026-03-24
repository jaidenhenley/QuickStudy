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
    static func makeGenerator(settings: AISettings) throws -> any CardGenerating {
        switch settings.mode {
        case .onDevice:
            return OnDeviceCardGenerationEngine()

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
}

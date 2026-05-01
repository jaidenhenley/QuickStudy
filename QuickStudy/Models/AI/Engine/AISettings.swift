//
//  AISettings.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/23/26.
//

import Combine
import Foundation

enum APIFormat: String, Codable, Hashable {
    case openAI
    case anthropic
}

@MainActor
@Observable
class AISettings {
    private static let defaults = UserDefaults.standard

    var mode: CardGenerationMode {
        didSet { Self.defaults.set(mode.rawValue, forKey: "aiSettings.mode") }
    }

    var apiFormat: APIFormat {
        didSet { Self.defaults.set(apiFormat.rawValue, forKey: "aiSettings.apiFormat") }
    }

    var endpoint: URL? {
        didSet { Self.defaults.set(endpoint?.absoluteString, forKey: "aiSettings.endpoint") }
    }

    var modelName: String? {
        didSet { Self.defaults.set(modelName, forKey: "aiSettings.modelName") }
    }

    var apiKey: String? {
        get { KeychainManager.loadAPIKey() }
    }

    init() {
        let d = Self.defaults
        self.mode = d.string(forKey: "aiSettings.mode")
            .flatMap(CardGenerationMode.init(rawValue:)) ?? .onDevice
        self.apiFormat = d.string(forKey: "aiSettings.apiFormat")
            .flatMap(APIFormat.init(rawValue:)) ?? .openAI
        self.endpoint = d.string(forKey: "aiSettings.endpoint")
            .flatMap(URL.init(string:))
        self.modelName = d.string(forKey: "aiSettings.modelName")
    }
}

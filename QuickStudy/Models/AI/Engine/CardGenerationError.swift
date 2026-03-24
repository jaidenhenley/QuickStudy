//
//  CardGenerationError.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/23/26.
//

import Foundation

enum CardGenerationError: LocalizedError {
    case missingAPIKey
    case invalidEndpoint
    case invalidResponse
    case decodingFailed
    case unsupportedOnDeviceModel
    case networkError(String)
    case badStatusCode(Int)
    case unsupportedProviderResponse
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing API key."
        case .invalidEndpoint:
            return "Invalid API endpoint."
        case .invalidResponse:
            return "The API returned an invalid response."
        case .decodingFailed:
            return "Failed to decode the API response."
        case .unsupportedOnDeviceModel:
            return "On-device AI is not available on this device."
        case .networkError(let message):
            return message
        case .badStatusCode(let code):
            return "The API returned status code \(code)."
        case .unsupportedProviderResponse:
            return "The API returned an unsupported response format."
        case .keychainError(let status):
            return "Failed to save API key (Keychain error \(status))."
        }
    }
}

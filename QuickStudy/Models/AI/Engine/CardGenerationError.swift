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
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case contextWindowExceeded
    case guardrailViolation
    case unsupportedLanguage
    case generationFailed
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
        case .deviceNotEligible:
            return "This iPhone doesn't support on-device AI."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to generate cards on this iPhone."
        case .modelNotReady:
            return "Apple Intelligence is still downloading. Try again in a few minutes."
        case .contextWindowExceeded:
            return "This page is too dense to process on this iPhone. Try scanning fewer pages at once."
        case .guardrailViolation:
            return "This content can't be turned into cards. Try a different page."
        case .unsupportedLanguage:
            return "On-device AI doesn't support this document's language yet."
        case .generationFailed:
            return "Couldn't draft cards from this. Try a different source."
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

    /// Shown to the user on the error screen so a support report names one cause.
    var code: String {
        switch self {
        case .invalidEndpoint:
            return "QS-400"
        case .missingAPIKey:
            return "QS-401"
        case .contextWindowExceeded:
            return "QS-413"
        case .unsupportedLanguage:
            return "QS-415"
        case .decodingFailed:
            return "QS-422"
        case .guardrailViolation:
            return "QS-451"
        case .generationFailed:
            return "QS-503"
        case .invalidResponse:
            return "QS-502"
        case .networkError:
            return "QS-504"
        case .unsupportedProviderResponse:
            return "QS-505"
        case .deviceNotEligible:
            return "QS-601"
        case .appleIntelligenceNotEnabled:
            return "QS-602"
        case .modelNotReady:
            return "QS-603"
        case .badStatusCode(let status):
            return "QS-H\(status)"
        case .keychainError(let status):
            return "QS-K\(status)"
        }
    }
}

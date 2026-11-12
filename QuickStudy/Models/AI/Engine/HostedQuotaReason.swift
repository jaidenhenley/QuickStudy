//
//  HostedQuotaReason.swift
//  QuickStudy
//

import Foundation

/// The server reports why a hosted draft hit a limit as a code, so the copy can be localized
/// on the iPhone instead of showing the Worker's English message.
enum HostedQuotaReason: Equatable, Sendable {
    case rateLimited
    case monthlyLimitReached
    case documentExceedsRemaining(needed: Int, remaining: Int)
    case freeGenerationInProgress
    case unspecified

    init(code: String?, needed: Int?, remaining: Int?) {
        switch code {
        case "rate_limited":
            self = .rateLimited
        case "monthly_limit":
            self = .monthlyLimitReached
        case "document_exceeds_remaining":
            if let needed, let remaining {
                self = .documentExceedsRemaining(needed: needed, remaining: remaining)
            } else {
                self = .monthlyLimitReached
            }
        case "free_generation_in_progress":
            self = .freeGenerationInProgress
        default:
            self = .unspecified
        }
    }

    var message: String {
        switch self {
        case .rateLimited:
            return String(localized: "Too many requests. Try again in a minute.")
        case .monthlyLimitReached:
            return String(localized: "Monthly Pro generations are used up.")
        case .documentExceedsRemaining(let needed, let remaining):
            return String(localized: "This document needs \(needed) generations and you have \(remaining) left this month. Try importing fewer pages.")
        case .freeGenerationInProgress:
            return String(localized: "Your free generation is already being drafted. Wait for it to finish.")
        case .unspecified:
            return String(localized: "You've reached your cloud generation limit. Try again later.")
        }
    }
}

//
//  MetricsSnapshot.swift
//  QuickStudy
//

import Foundation

/// Field names must match the quickstudy-api `/metrics` allowlist exactly — the worker
/// validates by name. `challenge` is left unset here and only filled in on the outgoing
/// copy built right before a flush; it never affects what gets persisted locally.
struct MetricsSnapshot: Codable, Equatable {
    var challenge: String?

    var hasOnDeviceModel = false
    var onboardingStarted = 0
    var onboardingCompleted = 0
    var firstGenerationCompleted = 0
    var firstGenerationDurationBucket: Int?
    var paywallShownOnboarding = 0
    var paywallShownPill = 0
    var paywallShownSettings = 0
    var paywallShownExhausted = 0
    var paywallShownTruncation = 0
    var paywallDismissedOnboarding = 0
    var paywallDismissedPill = 0
    var paywallDismissedSettings = 0
    var paywallDismissedExhausted = 0
    var paywallDismissedTruncation = 0
    var purchaseInitiated = 0
    var allowanceExhausted = false
    var generationsUsedBucket: Int?
    var truncationEvents = 0
    var daysSinceInstallAtPaywall: Int?
    var setsCreated = 0
    var sessionsCompleted = 0

    mutating func apply(_ event: AnalyticsEvent) {
        switch event {
        case .deviceCapability(let hasModel):
            hasOnDeviceModel = hasModel
        case .onboardingStarted:
            onboardingStarted += 1
        case .onboardingCompleted:
            onboardingCompleted += 1
        case .firstGenerationCompleted(let bucket):
            firstGenerationCompleted += 1
            firstGenerationDurationBucket = Self.clamp(bucket, max: 4)
        case .paywallShown(let surface):
            switch surface {
            case .onboarding: paywallShownOnboarding += 1
            case .pill: paywallShownPill += 1
            case .settings: paywallShownSettings += 1
            case .exhausted: paywallShownExhausted += 1
            case .truncation: paywallShownTruncation += 1
            }
        case .paywallDismissed(let surface):
            switch surface {
            case .onboarding: paywallDismissedOnboarding += 1
            case .pill: paywallDismissedPill += 1
            case .settings: paywallDismissedSettings += 1
            case .exhausted: paywallDismissedExhausted += 1
            case .truncation: paywallDismissedTruncation += 1
            }
        case .purchaseInitiated:
            purchaseInitiated += 1
        case .allowanceExhausted:
            allowanceExhausted = true
        case .generationsUsed(let bucket):
            generationsUsedBucket = Self.clamp(bucket, max: 3)
        case .truncationEvent:
            truncationEvents += 1
        case .setCreated:
            setsCreated += 1
        case .sessionCompleted:
            sessionsCompleted += 1
        }
    }

    private static func clamp(_ value: Int, max: Int) -> Int {
        Swift.min(Swift.max(value, 0), max)
    }
}

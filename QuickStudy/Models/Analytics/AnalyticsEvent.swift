//
//  AnalyticsEvent.swift
//  QuickStudy
//

import Foundation

enum PaywallSurface {
    case onboarding, pill, settings, exhausted, truncation
}

enum AnalyticsEvent {
    case deviceCapability(hasOnDeviceModel: Bool)
    case onboardingStarted
    case onboardingCompleted
    case firstGenerationCompleted(durationBucket: Int)
    case paywallShown(PaywallSurface)
    case paywallDismissed(PaywallSurface)
    case purchaseInitiated
    case allowanceExhausted
    case generationsUsed(bucket: Int)
    case truncationEvent
    case setCreated
    case sessionCompleted
}

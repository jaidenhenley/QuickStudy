//
//  PrivateCloud.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/15/26.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// The app's only entry point to Private Cloud Compute, and the only place that checks
// for iOS 27. Everything it returns is usable on iOS 26.
enum PrivateCloud {
    static var status: PrivateCloudStatus {
        #if canImport(FoundationModels)
        guard #available(iOS 27, *), !SimulatedDevice.lacksAppleIntelligence else { return .unavailable }
        let model = PrivateCloudComputeLanguageModel()
        guard model.isAvailable else { return .unavailable }
        let quota = model.quotaUsage
        switch quota.status {
        case .belowLimit(let usage):
            return .ready(approachingLimit: usage.isApproachingLimit)
        case .limitReached:
            return .quotaReached(resetsAt: quota.resetDate)
        @unknown default:
            return .unavailable
        }
        #else
        return .unavailable
        #endif
    }

    /// Nil whenever the status isn't `.ready`, so a caller moves on to its next engine
    /// without spending a request that would fail.
    static func makeEngine(progress: GenerationProgress?) -> (any CardGenerating)? {
        #if canImport(FoundationModels)
        guard #available(iOS 27, *), case .ready = status else { return nil }
        return PrivateCloudCardGenerationEngine(progress: progress)
        #else
        return nil
        #endif
    }

    static func prewarm() {
        #if canImport(FoundationModels)
        guard #available(iOS 27, *), case .ready = status else { return }
        LanguageModelSession(
            model: PrivateCloudComputeLanguageModel(),
            instructions: CardDraftingCore.cardInstructions
        ).prewarm()
        #endif
    }
}

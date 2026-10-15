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
        guard #available(iOS 27, *) else { return .unavailable }
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
}

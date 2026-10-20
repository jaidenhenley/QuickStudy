//
//  DraftingSetup.swift
//  QuickStudy
//

import Foundation

/// Where this iPhone can draft. Onboarding, the consent sheet and the free counter all
/// describe it, so they read it from one place and can't disagree.
enum DraftingSetup {
    case privateCloud, onDevice, cloudOnly

    @MainActor
    static func current(settings: AISettings) -> DraftingSetup {
        if PrivateCloud.status != .unavailable { return .privateCloud }
        if AICapability.state(for: settings) != .unsupportedDevice { return .onDevice }
        return .cloudOnly
    }
}

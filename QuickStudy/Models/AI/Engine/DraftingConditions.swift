//
//  DraftingConditions.swift
//  QuickStudy
//

import Foundation

/// Everything the engine plan depends on, gathered in one value so the plan can be
/// decided, and tested, without a device or a store.
struct DraftingConditions: Equatable {
    var mode: CardGenerationMode
    var consent: HostedConsent.Decision?
    var isPro: Bool
    var freeHostedGenerationUnused: Bool
    var hasOnDeviceModel: Bool
    var privateCloudReady: Bool
}

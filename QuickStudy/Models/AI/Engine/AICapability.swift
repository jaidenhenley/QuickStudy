//
//  AICapability.swift
//  QuickStudy
//

import Foundation

@MainActor
enum AICapability {
    enum State: Equatable {
        case ready
        /// Permanent for this hardware. The user gets manual entry, not an error.
        case unsupportedDevice
        case needsSetup(String)
    }

    static func state(for settings: AISettings) -> State {
        switch settings.mode {
        case .externalAPI:
            guard settings.endpoint != nil else {
                return .needsSetup(String(localized: "Add an API endpoint in Settings to generate cards."))
            }
            guard let key = settings.apiKey,
                  !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return .needsSetup(String(localized: "Add an API key in Settings to generate cards."))
            }
            return .ready

        case .onDevice:
            #if canImport(FoundationModels)
            do {
                try OnDeviceModelAvailability.check()
                return .ready
            } catch CardGenerationError.deviceNotEligible {
                return .unsupportedDevice
            } catch {
                return .needsSetup(
                    (error as? CardGenerationError)?.errorDescription
                        ?? String(localized: "On-device AI isn't ready yet. Try again in a few minutes.")
                )
            }
            #else
            return .unsupportedDevice
            #endif
        }
    }
}

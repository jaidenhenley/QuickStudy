//
//  OnDeviceModelAvailability.swift
//  QuickStudy
//

#if canImport(FoundationModels)
import FoundationModels

enum OnDeviceModelAvailability {
    static var isAvailable: Bool {
        guard !SimulatedDevice.lacksAppleIntelligence else { return false }
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    static func check() throws {
        if SimulatedDevice.lacksAppleIntelligence { throw CardGenerationError.deviceNotEligible }
        switch SystemLanguageModel.default.availability {
        case .available:
            return
        case .unavailable(.deviceNotEligible):
            throw CardGenerationError.deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled):
            throw CardGenerationError.appleIntelligenceNotEnabled
        case .unavailable(.modelNotReady):
            throw CardGenerationError.modelNotReady
        case .unavailable:
            throw CardGenerationError.modelNotReady
        }
    }
}
#endif

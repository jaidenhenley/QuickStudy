//
//  SimulatedDevice.swift
//  QuickStudy
//

import Foundation

/// A simulator uses the Mac's Apple Intelligence whichever iPhone it shows, so the paths
/// for iPhones without it can't be reached there. Set `QS_SIMULATE_NO_APPLE_INTELLIGENCE`
/// to 1 in the scheme to reach them. Compiled into debug simulator builds only.
enum SimulatedDevice {
    static var lacksAppleIntelligence: Bool {
        #if DEBUG && targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["QS_SIMULATE_NO_APPLE_INTELLIGENCE"] == "1"
        #else
        return false
        #endif
    }
}

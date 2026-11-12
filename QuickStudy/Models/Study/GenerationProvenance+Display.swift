//
//  GenerationProvenance+Display.swift
//  QuickStudy
//

import Foundation

extension GenerationProvenance.Engine {
    var displayName: String {
        switch self {
        case .onDevice: String(localized: "On this iPhone")
        case .privateCloud: String(localized: "Private Cloud Compute")
        case .cloud: String(localized: "QuickStudy Cloud")
        case .externalAPI: String(localized: "Your AI endpoint")
        }
    }

    var symbolName: String {
        switch self {
        case .onDevice: "iphone"
        case .privateCloud: "lock.icloud"
        case .cloud: "cloud"
        case .externalAPI: "server.rack"
        }
    }
}

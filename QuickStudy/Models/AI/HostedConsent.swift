//
//  HostedConsent.swift
//  QuickStudy
//

import Foundation

/// The one-time permission to send notes to QuickStudy's server. Nothing leaves the
/// iPhone for hosted generation, free or Pro, until this is `.granted`.
enum HostedConsent {
    enum Decision: String {
        case granted, declined
    }

    private static let key = "qs_hostedConsent"

    static var decision: Decision? { storedDecision() }

    static func storedDecision(defaults: UserDefaults = .standard) -> Decision? {
        defaults.string(forKey: key).flatMap(Decision.init(rawValue:))
    }

    static func record(_ decision: Decision, defaults: UserDefaults = .standard) {
        defaults.set(decision.rawValue, forKey: key)
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}

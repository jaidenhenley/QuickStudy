//
//  HostedConsent.swift
//  QuickStudy
//

import Foundation

/// The one-time permission to draft off this iPhone, on Private Cloud Compute or
/// QuickStudy's server. Nothing leaves the iPhone, free or Pro, until this is `.granted`.
enum HostedConsent {
    enum Decision: String {
        case granted, declined
    }

    /// Version 1 asked about QuickStudy's server only. A grant from then did not cover
    /// Private Cloud Compute, so it is asked again; a decline still stands.
    static let currentVersion = 2

    private static let key = "qs_hostedConsent"
    private static let versionKey = "qs_hostedConsentVersion"

    static var decision: Decision? { storedDecision() }

    static func storedDecision(defaults: UserDefaults = .standard) -> Decision? {
        guard let decision = defaults.string(forKey: key).flatMap(Decision.init(rawValue:)) else { return nil }
        if decision == .granted, defaults.integer(forKey: versionKey) < currentVersion { return nil }
        return decision
    }

    static func record(_ decision: Decision, defaults: UserDefaults = .standard) {
        defaults.set(decision.rawValue, forKey: key)
        defaults.set(currentVersion, forKey: versionKey)
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: versionKey)
    }
}

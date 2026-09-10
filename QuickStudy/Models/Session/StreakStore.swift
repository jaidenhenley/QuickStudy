//
//  StreakStore.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

/// Streaks derive from session history; only the days a freeze was spent need storing,
/// because a freeze applied today has to stay applied tomorrow.
enum StreakStore {
    private static let defaults = UserDefaults.standard
    private static let frozenKey = "qs_frozenDays"

    static var frozenDays: Set<Date> {
        let stamps = defaults.array(forKey: frozenKey) as? [Double] ?? []
        return Set(stamps.map { Date(timeIntervalSince1970: $0) })
    }

    static func setFrozenDays(_ days: Set<Date>) {
        defaults.set(days.map(\.timeIntervalSince1970), forKey: frozenKey)
    }
}

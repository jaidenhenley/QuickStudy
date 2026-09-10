//
//  StreakStore.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

enum StreakStore {
    private static let defaults = UserDefaults.standard
    private static let countKey = "qs_streakCount"
    private static let lastStudiedKey = "qs_lastStudiedDate"
    private static let seededKey = "qs_streakIsDemo"

    static var count: Int {
        defaults.integer(forKey: countKey)
    }

    static var lastStudied: Date? {
        defaults.object(forKey: lastStudiedKey) as? Date
    }

    static func record(count: Int, on date: Date) {
        defaults.set(count, forKey: countKey)
        defaults.set(date, forKey: lastStudiedKey)
        // A real session takes ownership of a streak that started as sample data.
        defaults.removeObject(forKey: seededKey)
    }

    /// Migration: clears a streak written by the earlier sample-seeding build.
    /// A streak the user has since studied into is left alone — `record` drops the flag.
    static func purgeSeededStreak() {
        guard defaults.bool(forKey: seededKey) else { return }
        defaults.removeObject(forKey: countKey)
        defaults.removeObject(forKey: lastStudiedKey)
        defaults.removeObject(forKey: seededKey)
    }
}

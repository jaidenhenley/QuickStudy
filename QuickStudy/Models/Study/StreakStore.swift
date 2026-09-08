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

    /// Never overwrites a real streak — only seeds when the user has no study history.
    static func seedDemoStreak(_ value: Int, calendar: Calendar = .current) {
        guard lastStudied == nil else { return }
        defaults.set(value, forKey: countKey)
        defaults.set(calendar.date(byAdding: .day, value: -1, to: Date()), forKey: lastStudiedKey)
        defaults.set(true, forKey: seededKey)
    }

    static func clearDemoStreak() {
        guard defaults.bool(forKey: seededKey) else { return }
        defaults.removeObject(forKey: countKey)
        defaults.removeObject(forKey: lastStudiedKey)
        defaults.removeObject(forKey: seededKey)
    }
}

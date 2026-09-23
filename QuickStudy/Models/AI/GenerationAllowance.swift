//
//  GenerationAllowance.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

/// Monthly free-generation quota. Rolls over on its own: the stored month stamp is
/// compared on read, so a new month resets the count without a scheduled task.
enum GenerationAllowance {
    static let monthlyLimit = 10

    private static let usedKey = "qs_aiGenerationsUsed"
    private static let monthKey = "qs_aiGenerationsMonth"

    static var used: Int { used() }

    static var remaining: Int { remaining() }

    static var isExhausted: Bool { remaining() == 0 }

    /// A stored month later than now means the clock was set back. The stored count
    /// stands rather than resetting, or winding the date back would refill the allowance.
    static func used(now: Date = Date(), defaults: UserDefaults = .standard) -> Int {
        guard defaults.integer(forKey: monthKey) >= monthStamp(for: now) else { return 0 }
        return defaults.integer(forKey: usedKey)
    }

    static func remaining(now: Date = Date(), defaults: UserDefaults = .standard) -> Int {
        max(0, monthlyLimit - used(now: now, defaults: defaults))
    }

    static func recordGeneration(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(used(now: now, defaults: defaults) + 1, forKey: usedKey)
        defaults.set(max(monthStamp(for: now), defaults.integer(forKey: monthKey)), forKey: monthKey)
    }

    static func resetDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
    }

    static func monthStamp(for date: Date, calendar: Calendar = .current) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        return (components.year ?? 0) * 12 + (components.month ?? 0)
    }
}

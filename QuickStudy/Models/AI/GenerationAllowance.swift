//
//  GenerationAllowance.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

/// Monthly free-generation quota. Rolls over on its own: the stored month key is
/// compared on read, so a new month resets the count without a scheduled task.
enum GenerationAllowance {
    static let monthlyLimit = 10

    private static let usedKey = "qs_aiGenerationsUsed"
    private static let monthKey = "qs_aiGenerationsMonth"
    private static let defaults = UserDefaults.standard

    static var used: Int {
        guard defaults.string(forKey: monthKey) == currentMonth else { return 0 }
        return defaults.integer(forKey: usedKey)
    }

    static var remaining: Int {
        max(0, monthlyLimit - used)
    }

    static func recordGeneration() {
        let next = used + 1
        defaults.set(next, forKey: usedKey)
        defaults.set(currentMonth, forKey: monthKey)
    }

    private static var currentMonth: String {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
}

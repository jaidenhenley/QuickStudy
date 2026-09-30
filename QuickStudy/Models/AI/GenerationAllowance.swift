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
        restoreFromKeychainIfNeeded(defaults: defaults)
        guard defaults.integer(forKey: monthKey) >= monthStamp(for: now) else { return 0 }
        return defaults.integer(forKey: usedKey)
    }

    static func remaining(now: Date = Date(), defaults: UserDefaults = .standard) -> Int {
        max(0, monthlyLimit - used(now: now, defaults: defaults))
    }

    static func recordGeneration(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(used(now: now, defaults: defaults) + 1, forKey: usedKey)
        defaults.set(max(monthStamp(for: now), defaults.integer(forKey: monthKey)), forKey: monthKey)
        mirrorToKeychain(defaults: defaults)
    }

    // UserDefaults is wiped on reinstall and the Keychain is not, so the count is mirrored
    // there to stop a reinstall from refilling the allowance. Only the app's real store is
    // mirrored; tests inject their own suites and must not share Keychain state.
    private static func restoreFromKeychainIfNeeded(defaults: UserDefaults) {
        guard defaults === UserDefaults.standard,
              defaults.object(forKey: monthKey) == nil,
              let stored = KeychainManager.load(account: .generationAllowance) else { return }
        let parts = stored.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return }
        defaults.set(parts[0], forKey: monthKey)
        defaults.set(parts[1], forKey: usedKey)
    }

    private static func mirrorToKeychain(defaults: UserDefaults) {
        guard defaults === UserDefaults.standard else { return }
        let value = "\(defaults.integer(forKey: monthKey)):\(defaults.integer(forKey: usedKey))"
        do {
            try KeychainManager.save(value, account: .generationAllowance)
        } catch {
            // The UserDefaults copy is already written; losing the mirror only means a
            // reinstall this month would restore the allowance, which is not worth failing over.
        }
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

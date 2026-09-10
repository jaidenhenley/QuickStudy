//
//  StreakCalculator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

struct StreakSummary {
    enum DayState {
        case studied
        case frozen
        case missed
        case today
        case future
    }

    let current: Int
    let longest: Int
    let week: [DayState]
    let freezesAvailable: Int
}

enum StreakCalculator {
    /// One freeze per seven studied days. Freezes are earned, so forgiveness cannot be farmed.
    static let daysPerFreeze = 7

    static func summary(
        studiedDays: Set<Date>,
        frozenDays: Set<Date>,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> StreakSummary {
        let today = calendar.startOfDay(for: now)

        var cursor = today
        // Today not being done yet must not break a streak that is otherwise intact.
        if !studiedDays.contains(today) {
            cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }

        var current = 0
        while true {
            if studiedDays.contains(cursor) {
                current += 1
            } else if !frozenDays.contains(cursor) {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let earned = studiedDays.count / daysPerFreeze

        return StreakSummary(
            current: current,
            longest: max(current, longestRun(studiedDays: studiedDays, frozenDays: frozenDays, calendar: calendar)),
            week: weekStates(studiedDays: studiedDays, frozenDays: frozenDays, today: today, calendar: calendar),
            freezesAvailable: max(0, earned - frozenDays.count)
        )
    }

    /// Consumes freezes to cover gaps behind an active streak. The result must be
    /// persisted — a freeze applied today has to stay applied tomorrow.
    static func applyingFreezes(
        studiedDays: Set<Date>,
        frozenDays: Set<Date>,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Set<Date> {
        let today = calendar.startOfDay(for: now)
        guard let mostRecent = studiedDays.filter({ $0 < today }).max() else { return frozenDays }

        var updated = frozenDays
        var remaining = max(0, studiedDays.count / daysPerFreeze - frozenDays.count)
        var cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        while cursor > mostRecent, remaining > 0 {
            if !studiedDays.contains(cursor) && !updated.contains(cursor) {
                updated.insert(cursor)
                remaining -= 1
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return updated
    }

    private static func longestRun(
        studiedDays: Set<Date>,
        frozenDays: Set<Date>,
        calendar: Calendar
    ) -> Int {
        let covered = studiedDays.union(frozenDays).sorted()
        guard !covered.isEmpty else { return 0 }

        var longest = 0
        var run = 0
        var previous: Date?

        for day in covered {
            if let previous,
               let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                run += 1
            } else {
                run = 1
            }
            // A run of only frozen days is not a streak.
            if studiedDays.contains(day) { longest = max(longest, run) }
            previous = day
        }
        return longest
    }

    private static func weekStates(
        studiedDays: Set<Date>,
        frozenDays: Set<Date>,
        today: Date,
        calendar: Calendar
    ) -> [StreakSummary.DayState] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        return (0..<7).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            if studiedDays.contains(day) { return .studied }
            if frozenDays.contains(day) { return .frozen }
            if calendar.isDate(day, inSameDayAs: today) { return .today }
            return day > today ? .future : .missed
        }
    }
}

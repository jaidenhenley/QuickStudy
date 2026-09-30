//
//  GenerationAllowanceTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct GenerationAllowanceTests {
    private func makeDefaults(_ name: String = #function) -> UserDefaults {
        let suiteName = "GenerationAllowanceTests.\(name).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func freshStateHasFullAllowance() {
        let defaults = makeDefaults()
        let now = Date()

        #expect(GenerationAllowance.used(now: now, defaults: defaults) == 0)
        #expect(GenerationAllowance.remaining(now: now, defaults: defaults) == GenerationAllowance.monthlyLimit)
    }

    @Test func recordingDecrementsRemaining() {
        let defaults = makeDefaults()
        let now = Date()

        GenerationAllowance.recordGeneration(now: now, defaults: defaults)
        GenerationAllowance.recordGeneration(now: now, defaults: defaults)

        #expect(GenerationAllowance.used(now: now, defaults: defaults) == 2)
        #expect(GenerationAllowance.remaining(now: now, defaults: defaults) == GenerationAllowance.monthlyLimit - 2)
    }

    @Test func recordingPastLimitClampsRemainingAtZero() {
        let defaults = makeDefaults()
        let now = Date()

        for _ in 0..<(GenerationAllowance.monthlyLimit + 5) {
            GenerationAllowance.recordGeneration(now: now, defaults: defaults)
        }

        #expect(GenerationAllowance.used(now: now, defaults: defaults) == GenerationAllowance.monthlyLimit + 5)
        #expect(GenerationAllowance.remaining(now: now, defaults: defaults) == 0)
    }

    @Test func nextMonthRollsUsedBackToZero() {
        let defaults = makeDefaults()
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15))!
        let nextMonth = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!

        GenerationAllowance.recordGeneration(now: now, defaults: defaults)
        GenerationAllowance.recordGeneration(now: now, defaults: defaults)
        #expect(GenerationAllowance.used(now: now, defaults: defaults) == 2)

        #expect(GenerationAllowance.used(now: nextMonth, defaults: defaults) == 0)
        #expect(GenerationAllowance.remaining(now: nextMonth, defaults: defaults) == GenerationAllowance.monthlyLimit)
    }

    @Test func clockSetBackAMonthKeepsTheStoredCount() {
        let defaults = makeDefaults()
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let earlier = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10))!

        GenerationAllowance.recordGeneration(now: now, defaults: defaults)
        GenerationAllowance.recordGeneration(now: now, defaults: defaults)

        #expect(GenerationAllowance.used(now: earlier, defaults: defaults) == 2)
        GenerationAllowance.recordGeneration(now: earlier, defaults: defaults)
        #expect(GenerationAllowance.used(now: earlier, defaults: defaults) == 3)
        #expect(GenerationAllowance.used(now: now, defaults: defaults) == 3)
    }

    @Test func resetDateIsFirstOfNextMonthAtStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 15, hour: 13, minute: 30))!

        let resetDate = GenerationAllowance.resetDate(now: now, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: resetDate)

        #expect(components.year == 2026)
        #expect(components.month == 4)
        #expect(components.day == 1)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
    }

    @Test func resetDateCrossesDecemberIntoJanuary() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 12, day: 20))!

        let resetDate = GenerationAllowance.resetDate(now: now, calendar: calendar)
        let components = calendar.dateComponents([.year, .month, .day], from: resetDate)

        #expect(components.year == 2027)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }
}

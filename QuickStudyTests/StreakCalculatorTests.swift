//
//  StreakCalculatorTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct StreakCalculatorTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func day(_ offset: Int, from today: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today)!
    }

    private var today: Date {
        calendar.startOfDay(for: calendar.date(from: DateComponents(year: 2026, month: 6, day: 15))!)
    }

    @Test func consecutiveDaysCountAsCurrentStreak() {
        let today = today
        let studied: Set<Date> = [day(0, from: today), day(-1, from: today), day(-2, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)

        #expect(summary.current == 3)
    }

    @Test func todayNotYetStudiedDoesNotBreakStreak() {
        let today = today
        let studied: Set<Date> = [day(-1, from: today), day(-2, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)

        #expect(summary.current == 2)
    }

    @Test func gapBreaksStreak() {
        let today = today
        let studied: Set<Date> = [day(0, from: today), day(-1, from: today), day(-3, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)

        #expect(summary.current == 2)
    }

    @Test func frozenDayBridgesGap() {
        let today = today
        let studied: Set<Date> = [day(0, from: today), day(-1, from: today), day(-3, from: today)]
        let frozen: Set<Date> = [day(-2, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: frozen, now: today, calendar: calendar)

        #expect(summary.current == 3)
    }

    @Test func longestIgnoresRunsMadeOnlyOfFrozenDays() {
        let today = today
        let studied: Set<Date> = [day(-10, from: today)]
        let frozen: Set<Date> = [day(-1, from: today), day(-2, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: frozen, now: today, calendar: calendar)

        #expect(summary.longest == 1)
    }

    @Test func freezesAvailableIsStudiedOverSevenMinusFrozenCount() {
        let today = today
        let studied = Set((1...14).map { day(-$0, from: today) })

        let summaryNoFreeze = StreakCalculator.summary(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)
        #expect(summaryNoFreeze.freezesAvailable == 2)

        let summaryOneSpent = StreakCalculator.summary(studiedDays: studied, frozenDays: [day(-20, from: today)], now: today, calendar: calendar)
        #expect(summaryOneSpent.freezesAvailable == 1)
    }

    @Test func freezesAvailableNeverGoesNegative() {
        let today = today
        let studied: Set<Date> = [day(0, from: today)]
        let frozen: Set<Date> = [day(-1, from: today), day(-2, from: today)]

        let summary = StreakCalculator.summary(studiedDays: studied, frozenDays: frozen, now: today, calendar: calendar)

        #expect(summary.freezesAvailable == 0)
    }

    @Test func applyingFreezesConsumesAtMostEarnedFreezes() {
        let today = today
        let studied = Set((2...8).map { day(-$0, from: today) })

        let updated = StreakCalculator.applyingFreezes(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)

        #expect(updated.count == 1)
        #expect(updated.contains(day(-1, from: today)))
    }

    @Test func applyingFreezesOnlyFillsGapsBehindMostRecentStudiedDay() {
        let today = today
        let studied = Set((3...16).map { day(-$0, from: today) })

        let updated = StreakCalculator.applyingFreezes(studiedDays: studied, frozenDays: [], now: today, calendar: calendar)

        #expect(updated.contains(day(-1, from: today)))
        #expect(updated.contains(day(-2, from: today)))
        #expect(updated.count == 2)
    }
}

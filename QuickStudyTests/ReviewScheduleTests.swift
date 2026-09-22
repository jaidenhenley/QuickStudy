//
//  ReviewScheduleTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct ReviewScheduleTests {
    @Test(arguments: [
        (0, 0), (1, 1), (2, 3), (3, 7), (4, 14), (5, 30),
    ])
    func intervalsMatchTable(box: Int, expectedDays: Int) {
        #expect(ReviewSchedule.interval(forBox: box) == expectedDays)
    }

    @Test func promoteCapsAtMasteredBox() {
        #expect(ReviewSchedule.promote(ReviewSchedule.masteredBox) == ReviewSchedule.masteredBox)
        #expect(ReviewSchedule.promote(ReviewSchedule.masteredBox - 1) == ReviewSchedule.masteredBox)
        #expect(ReviewSchedule.promote(0) == 1)
    }

    @Test func demoteDropsTwoBoxes() {
        #expect(ReviewSchedule.demote(4) == 2)
        #expect(ReviewSchedule.demote(5) == 3)
    }

    @Test func demoteFloorsAtNewBox() {
        #expect(ReviewSchedule.demote(1) == ReviewSchedule.newBox)
        #expect(ReviewSchedule.demote(0) == ReviewSchedule.newBox)
    }

    @Test func progressIsZeroAtNewBoxAndOneAtMasteredBox() {
        #expect(ReviewSchedule.progress(forBox: ReviewSchedule.newBox) == 0)
        #expect(ReviewSchedule.progress(forBox: ReviewSchedule.masteredBox) == 1)
    }

    @Test func newDueDateIsStartOfDayPlusInterval() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let from = calendar.date(from: DateComponents(year: 2026, month: 6, day: 15, hour: 9, minute: 45))!

        let dueDate = ReviewSchedule.newDueDate(forBox: 3, from: from, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 6, day: 22))!

        #expect(dueDate == expected)
    }
}

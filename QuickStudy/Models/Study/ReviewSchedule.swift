//
//  ReviewSchedule.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/7/26.
//

import Foundation

enum ReviewSchedule {
    static let newBox = 0
    static let masteredBox = 5
    
    /// Box 0 is same-day: a new or freshly-missed card is due immediately.
    private static let intervalDays = [0, 1, 3, 7, 14, 30]
    
    static func interval(forBox box: Int) -> Int {
        intervalDays[min(max(box, newBox), intervalDays.count - 1)]
    }
    
    static func promote(_ box: Int) -> Int {
        min(box + 1, masteredBox)
    }
    
    /// Drops two boxes, not to zero: a mature card that slips once should lose
    /// more than a single step but not go back to day one.
    static func demote(_ box: Int) -> Int {
        max(box - 2, newBox)
    }
    
    static func newDueDate(
        forBox box: Int,
        from date: Date = Date(),
        calendar: Calendar = .current
    ) -> Date {
        let day = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: interval(forBox: box), to: day) ?? day
    }
    
    static func progress(forBox box: Int) -> Double {
        Double(min(max(box, newBox), masteredBox)) / Double(masteredBox)
    }
}

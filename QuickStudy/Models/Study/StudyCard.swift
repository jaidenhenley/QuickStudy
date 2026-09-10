//
//  StudyCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/19/26.
//

import Foundation

struct StudyCard: Identifiable, Codable, Equatable {
    let id: UUID
    var question: String
    var answer: String
    var approved: Bool
    var missCount: Int
    var box: Int
    var dueDate: Date?
    var lastReviewedAt: Date?
    var source: CardSource?

    init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        approved: Bool,
        missCount: Int = 0,
        box: Int = ReviewSchedule.newBox,
        dueDate: Date? = nil,
        lastReviewedAt: Date? = nil,
        source: CardSource? = nil
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.approved = approved
        self.missCount = missCount
        self.box = box
        self.dueDate = dueDate
        self.lastReviewedAt = lastReviewedAt
        self.source = source
    }

    var isMastered: Bool {
        box >= ReviewSchedule.masteredBox
    }

    var progress: Double {
        ReviewSchedule.progress(forBox: box)
    }

    /// A nil `dueDate` means the card has never been scheduled, so it is due now.
    func isDue(asOf date: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let dueDate else { return true }
        return calendar.startOfDay(for: dueDate) <= calendar.startOfDay(for: date)
    }

    mutating func recordAnswer(
        correct: Bool,
        on date: Date = Date(),
        calendar: Calendar = .current
    ) {
        box = correct ? ReviewSchedule.promote(box) : ReviewSchedule.demote(box)
        if !correct { missCount += 1 }
        lastReviewedAt = date
        dueDate = ReviewSchedule.newDueDate(forBox: box, from: date, calendar: calendar)
    }

    /// Explicit so cards saved before scheduling existed keep decoding.
    private enum CodingKeys: String, CodingKey {
        case id
        case question
        case answer
        case approved
        case missCount
        case box
        case dueDate
        case lastReviewedAt
        case source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        question = try container.decode(String.self, forKey: .question)
        answer = try container.decode(String.self, forKey: .answer)
        approved = try container.decode(Bool.self, forKey: .approved)
        missCount = try container.decode(Int.self, forKey: .missCount)
        box = try container.decodeIfPresent(Int.self, forKey: .box) ?? ReviewSchedule.newBox
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
        source = try container.decodeIfPresent(CardSource.self, forKey: .source)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(question, forKey: .question)
        try container.encode(answer, forKey: .answer)
        try container.encode(approved, forKey: .approved)
        try container.encode(missCount, forKey: .missCount)
        try container.encode(box, forKey: .box)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(lastReviewedAt, forKey: .lastReviewedAt)
        try container.encodeIfPresent(source, forKey: .source)
    }
}

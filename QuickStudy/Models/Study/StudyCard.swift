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

    init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        approved: Bool,
        missCount: Int = 0
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.approved = approved
        self.missCount = missCount
    }
}

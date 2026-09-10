//
//  StudySession.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

struct StudySession: Identifiable, Codable {
    enum AnswerMode: String, Codable {
        case multipleChoice
        case typed
    }

    struct Result: Codable {
        let cardID: UUID
        let setID: UUID
        let correct: Bool
        let answeredAt: Date
        let mode: AnswerMode
        let boxBefore: Int
        let boxAfter: Int
    }

    let id: UUID
    let startedAt: Date
    var endedAt: Date?
    var results: [Result]

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        results: [Result] = []
    ) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.results = results
    }

    var cardCount: Int { results.count }
    var correctCount: Int { results.filter(\.correct).count }
    var accuracy: Double { results.isEmpty ? 0 : Double(correctCount) / Double(cardCount) }
    var elapsed: TimeInterval { (endedAt ?? Date()).timeIntervalSince(startedAt) }

    var elapsedLabel: String {
        let total = Int(elapsed)
        return "\(total / 60)m \(total % 60)s"
    }

    /// Cards missed more than once — the NEEDS REINFORCEMENT row on Session Complete.
    var reinforcementCardIDs: [UUID] {
        Dictionary(grouping: results.filter { !$0.correct }, by: \.cardID)
            .filter { $0.value.count > 1 }
            .keys
            .sorted { $0.uuidString < $1.uuidString }
    }
}

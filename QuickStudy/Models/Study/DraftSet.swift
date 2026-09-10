//
//  DraftSet.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

/// Generation output awaiting review. Persisted so a crash mid-review doesn't cost the
/// user their cards and a generation from their monthly allowance.
struct DraftSet: Identifiable, Codable {
    let id: UUID
    var title: String
    var document: StudyDocument
    var cards: [StudyCard]
    var sourceType: StudySourceType
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        document: StudyDocument,
        cards: [StudyCard],
        sourceType: StudySourceType,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.document = document
        self.cards = cards
        self.sourceType = sourceType
        self.createdAt = createdAt
    }

    var pageCount: Int { document.pageBreaks?.count ?? 1 }

    mutating func remove(_ cardID: UUID) {
        cards.removeAll { $0.id == cardID }
    }

    func committed() -> StudySet {
        StudySet(title: title, document: document, cards: cards, sourceType: sourceType)
    }
}

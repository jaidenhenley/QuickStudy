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
    var wasTruncated: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        document: StudyDocument,
        cards: [StudyCard],
        sourceType: StudySourceType,
        wasTruncated: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.document = document
        self.cards = cards
        self.sourceType = sourceType
        self.wasTruncated = wasTruncated
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        document = try container.decode(StudyDocument.self, forKey: .document)
        cards = try container.decode([StudyCard].self, forKey: .cards)
        sourceType = try container.decode(StudySourceType.self, forKey: .sourceType)
        wasTruncated = try container.decodeIfPresent(Bool.self, forKey: .wasTruncated) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    var pageCount: Int { document.pageBreaks?.count ?? 1 }

    mutating func remove(_ cardID: UUID) {
        cards.removeAll { $0.id == cardID }
    }

    func committed() -> StudySet {
        StudySet(title: title, document: document, cards: cards, sourceType: sourceType)
    }
}

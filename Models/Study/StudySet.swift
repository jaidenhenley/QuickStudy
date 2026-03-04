//
//  StudySet.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/20/26.
//

import Foundation

struct StudySet: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var document: StudyDocument
    var cards: [StudyCard]
    var sourceType: StudySourceType
    var isDemo: Bool

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        document: StudyDocument,
        cards: [StudyCard],
        sourceType: StudySourceType,
        isDemo: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.document = document
        self.cards = cards
        self.sourceType = sourceType
        self.isDemo = isDemo
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case createdAt
        case updatedAt
        case document
        case cards
        case sourceType
        case isDemo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        document = try container.decode(StudyDocument.self, forKey: .document)
        cards = try container.decode([StudyCard].self, forKey: .cards)
        sourceType = try container.decode(StudySourceType.self, forKey: .sourceType)
        isDemo = try container.decodeIfPresent(Bool.self, forKey: .isDemo) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(document, forKey: .document)
        try container.encode(cards, forKey: .cards)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encode(isDemo, forKey: .isDemo)
    }
}

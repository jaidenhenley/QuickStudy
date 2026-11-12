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
    var provenance: GenerationProvenance?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        document: StudyDocument,
        cards: [StudyCard],
        sourceType: StudySourceType,
        wasTruncated: Bool = false,
        provenance: GenerationProvenance? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.document = document
        self.cards = cards
        self.sourceType = sourceType
        self.wasTruncated = wasTruncated
        self.provenance = provenance
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
        provenance = try container.decodeIfPresent(GenerationProvenance.self, forKey: .provenance)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// Choose Pages keeps the skipped pages as empty placeholders so card sources keep the
    /// PDF's real page numbers; only pages that hold text count as drafted.
    var contentPages: [Int] {
        guard let breaks = document.pageBreaks, !breaks.isEmpty else { return [1] }
        let lines = document.lines
        return breaks.indices.filter { index in
            let start = breaks[index]
            let end = breaks.indices.contains(index + 1) ? breaks[index + 1] : lines.count
            guard start < end, end <= lines.count else { return false }
            return lines[start..<end].contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        .map { $0 + 1 }
    }

    var pageCount: Int { max(contentPages.count, 1) }

    /// "page 4", "pages 4 to 9", or "6 pages" when the chosen pages aren't contiguous.
    var pageRangeLabel: String? {
        guard document.pageBreaks != nil, let first = contentPages.first, let last = contentPages.last else { return nil }
        if contentPages.count == 1 { return String(localized: "page \(first)") }
        return last - first + 1 == contentPages.count
            ? String(localized: "pages \(first) to \(last)")
            : String(localized: "\(contentPages.count) pages")
    }

    mutating func remove(_ cardID: UUID) {
        cards.removeAll { $0.id == cardID }
    }

    func committed() -> StudySet {
        StudySet(title: title, document: document, cards: cards, sourceType: sourceType, provenance: provenance)
    }

    /// Only on-device and Private Cloud drafts spend a free generation; hosted Pro and
    /// the user's own API key don't, so the warning mustn't claim they did.
    var discardWarning: String {
        switch (provenance?.engine, cards.isEmpty) {
        case (.onDevice, true), (.privateCloud, true):
            return String(localized: "This draft will be deleted. This used one of your free generations.")
        case (.onDevice, false), (.privateCloud, false):
            return String(localized: "The \(cards.count) drafted cards will be deleted. This used one of your free generations.")
        case (_, true):
            return String(localized: "This draft will be deleted.")
        case (_, false):
            return String(localized: "The \(cards.count) drafted cards will be deleted.")
        }
    }
}

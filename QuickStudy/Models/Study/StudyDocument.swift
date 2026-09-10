//
//  StudyDocument.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/18/26.
//

import Foundation

struct StudyDocument: Codable, Equatable {
    var title: String
    var lines: [String]
    /// Line index where each page begins. Nil for pasted text, which has no pages.
    var pageBreaks: [Int]?

    init(title: String, lines: [String], pageBreaks: [Int]? = nil) {
        self.title = title
        self.lines = lines
        self.pageBreaks = pageBreaks
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case lines
        case pageBreaks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        lines = try container.decode([String].self, forKey: .lines)
        pageBreaks = try container.decodeIfPresent([Int].self, forKey: .pageBreaks)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(lines, forKey: .lines)
        try container.encodeIfPresent(pageBreaks, forKey: .pageBreaks)
    }

    func page(containing lineIndex: Int) -> Int? {
        guard let pageBreaks, !pageBreaks.isEmpty else { return nil }
        return pageBreaks.lastIndex { $0 <= lineIndex }.map { $0 + 1 }
    }

    var paragraphText: String {
        var paragraphs: [String] = []
        var current: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                if !current.isEmpty {
                    paragraphs.append(current.joined(separator: " "))
                    current.removeAll(keepingCapacity: true)
                }
            } else {
                current.append(trimmed)
            }
        }

        if !current.isEmpty {
            paragraphs.append(current.joined(separator: " "))
        }

        return paragraphs.joined(separator: "\n\n")
    }
}

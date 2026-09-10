//
//  CardSourceLocator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

/// Maps a model-supplied excerpt back onto the document. The model quotes the source;
/// locating it stays deterministic here rather than trusting the model to count lines.
enum CardSourceLocator {
    static func locate(excerpt: String, in document: StudyDocument) -> CardSource? {
        let needle = normalized(excerpt)
        guard !needle.isEmpty else { return nil }

        guard let range = matchRange(needle: needle, lines: document.lines) else {
            // Unmatched excerpts still carry their text so "Why" has something to show.
            return CardSource(
                documentTitle: document.title,
                page: nil,
                paragraph: nil,
                lineRange: nil,
                excerpt: excerpt
            )
        }

        return CardSource(
            documentTitle: document.title,
            page: document.page(containing: range.lowerBound),
            paragraph: paragraphIndex(ofLine: range.lowerBound, in: document.lines),
            lineRange: range,
            excerpt: document.lines[range].joined(separator: " ")
        )
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func matchRange(needle: String, lines: [String]) -> ClosedRange<Int>? {
        let normalizedLines = lines.map(normalized)

        for start in normalizedLines.indices {
            var joined = ""
            for end in start..<normalizedLines.count {
                if !joined.isEmpty { joined += " " }
                joined += normalizedLines[end]

                if joined.contains(needle) { return start...end }
                if joined.count > needle.count * 2 { break }
            }
        }
        return nil
    }

    private static func paragraphIndex(ofLine line: Int, in lines: [String]) -> Int {
        var paragraph = 1
        for index in 0..<line where lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
            paragraph += 1
        }
        return paragraph
    }
}

//
//  SetTitleSuggester.swift
//  QuickStudy
//

import Foundation

/// Names a set from its own text so a Library of pasted notes isn't a wall of identical
/// "Pasted Notes" tiles. Local and instant — no model call for a label.
enum SetTitleSuggester {
    private static let headingLength = 60
    private static let subjectLength = 40
    private static let fallbackWords = 4
    private static let definingVerbs = [" is ", " are ", " was ", " were ", " describes ", " refers to "]

    static func title(from lines: [String]) -> String? {
        guard let first = lines
            .lazy
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) else { return nil }

        if first.count <= headingLength {
            return cleaned(first)
        }

        // Notes usually open by defining their topic: "Photosynthesis is the process…".
        for verb in definingVerbs {
            if let range = first.range(of: verb) {
                let subject = String(first[..<range.lowerBound])
                if (3...subjectLength).contains(subject.count) { return cleaned(subject) }
            }
        }

        return cleaned(first.split(separator: " ").prefix(fallbackWords).joined(separator: " "))
    }

    private static func cleaned(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard trimmed.count >= 3 else { return nil }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}

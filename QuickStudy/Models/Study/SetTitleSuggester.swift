//
//  SetTitleSuggester.swift
//  QuickStudy
//

import Foundation
import NaturalLanguage

/// Names a set from its own text so a Library of pasted notes isn't a wall of identical
/// "Pasted Notes" tiles. Local and instant — no model call for a label.
enum SetTitleSuggester {
    private static let headingLength = 60
    private static let subjectLength = 40
    private static let fallbackWords = 4
    private static let definingVerbs: [NLLanguage: [String]] = [
        .english: [" is ", " are ", " was ", " were ", " describes ", " refers to "],
        .spanish: [" es ", " son ", " era ", " fue "],
        .french: [" est ", " sont ", " était "],
        .german: [" ist ", " sind ", " war ", " bezeichnet "],
        .portuguese: [" é ", " são ", " era ", " foi "],
        .japanese: ["とは", "は、", "は"],
        .korean: ["이란 ", "란 ", "은 ", "는 "]
    ]
    private static let clauseBreaks = CharacterSet(charactersIn: "、，。：:,;")

    static func title(from lines: [String]) -> String? {
        guard let first = lines
            .lazy
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty }) else { return nil }

        if first.count <= headingLength {
            return cleaned(first)
        }

        // Notes usually open by defining their topic: "Photosynthesis is the process…".
        let language = SourceLanguage.dominant(in: first) ?? .english
        for verb in definingVerbs[language] ?? [] {
            if let range = first.range(of: verb) {
                let subject = String(first[..<range.lowerBound])
                if (minimumSubject(in: language)...subjectLength).contains(subject.count) { return cleaned(subject) }
            }
        }

        let opening = first.split(separator: " ").prefix(fallbackWords).joined(separator: " ")
        guard opening.count > subjectLength else { return cleaned(opening) }
        // Text without spaces is one long "word", so it is cut at its first clause instead.
        let clause = opening.components(separatedBy: clauseBreaks).first ?? opening
        return cleaned(String(clause.prefix(subjectLength)))
    }

    private static func minimumSubject(in language: NLLanguage) -> Int {
        language == .japanese || language == .korean ? 2 : 3
    }

    private static func cleaned(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let minimum = trimmed.unicodeScalars.contains { $0.value >= 0x3040 } ? 2 : 3
        guard trimmed.count >= minimum else { return nil }
        return trimmed.prefix(1).uppercased() + trimmed.dropFirst()
    }
}

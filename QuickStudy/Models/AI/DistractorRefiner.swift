//
//  DistractorRefiner.swift
//  QuickStudy
//

import Foundation

/// The model treats distractors as a fifth field and fails in predictable ways: it
/// paraphrases the correct answer, writes options far shorter than it, and invents
/// vocabulary that never appears in the source. Exact-match filtering caught none of these.
enum DistractorRefiner {
    private static let paraphraseThreshold = 0.7
    private static let minLengthRatio = 0.4
    private static let maxLengthRatio = 2.5

    static func refine(_ candidates: [String], answer: String, source: String) -> [String] {
        accept(candidates, answer: answer, existing: [], needed: 3, sourceTokens: tokens(source))
    }

    /// Other cards' answers, used only when the model produced fewer than three usable
    /// options. These legitimately share no vocabulary with this card's source, so the
    /// source check is skipped.
    static func backfill(_ pool: [String], answer: String, existing: [String], needed: Int) -> [String] {
        accept(pool, answer: answer, existing: existing, needed: needed, sourceTokens: nil)
    }

    private static func accept(
        _ candidates: [String],
        answer: String,
        existing: [String],
        needed: Int,
        sourceTokens: Set<String>?
    ) -> [String] {
        guard needed > 0 else { return [] }

        let answerTokens = tokens(answer)
        guard !answerTokens.isEmpty else { return [] }

        var kept: [String] = []
        var seen = existing.map(tokens)

        for candidate in candidates {
            let text = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            let ratio = Double(text.count) / Double(max(1, answer.count))
            guard ratio >= minLengthRatio, ratio <= maxLengthRatio else { continue }

            let candidateTokens = tokens(text)
            guard !candidateTokens.isEmpty else { continue }
            guard similarity(candidateTokens, answerTokens) < paraphraseThreshold else { continue }
            if let sourceTokens, candidateTokens.isDisjoint(with: sourceTokens) { continue }
            guard !seen.contains(where: { similarity($0, candidateTokens) >= paraphraseThreshold }) else { continue }

            kept.append(text)
            seen.append(candidateTokens)
            if kept.count == needed { break }
        }
        return kept
    }

    /// Words of three or more characters stand in for a stopword list. A real one would
    /// need to be per-language, and the threshold comparisons are tolerant enough without it.
    private static func tokens(_ text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 }
        )
    }

    private static func similarity(_ a: Set<String>, _ b: Set<String>) -> Double {
        let union = a.union(b)
        guard !union.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(union.count)
    }
}

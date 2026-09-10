//
//  DistractorRefiner.swift
//  QuickStudy
//

import Foundation

/// The model treats distractors as a fifth field and fails in predictable ways: it
/// paraphrases the correct answer, writes options far shorter than it, and invents
/// vocabulary that never appears in the source. Exact-match filtering caught none of these.
enum DistractorRefiner {
    private nonisolated static let paraphraseThreshold = 0.7
    private nonisolated static let minLengthRatio = 0.4
    private nonisolated static let maxLengthRatio = 2.5
    private nonisolated static let absoluteSlack = 20

    nonisolated static func refine(_ candidates: [String], answer: String, source: String) -> [String] {
        accept(candidates, answer: answer, existing: [], needed: 3, sourceTokens: tokens(source))
    }

    /// Other cards' answers, used when the model produced fewer than three usable options.
    /// These legitimately share no vocabulary with this card's source, so the source check
    /// is skipped.
    nonisolated static func backfill(_ pool: [String], answer: String, existing: [String], needed: Int) -> [String] {
        accept(pool, answer: answer, existing: existing, needed: needed, sourceTokens: nil)
    }

    /// Last resort. Every quality rule is dropped except exact duplication, because a
    /// two-option "multiple choice" question is worse than a weak distractor.
    nonisolated static func pad(_ pool: [String], answer: String, existing: [String], needed: Int) -> [String] {
        accept(pool, answer: answer, existing: existing, needed: needed, sourceTokens: nil, enforceQuality: false)
    }

    nonisolated private static func accept(
        _ candidates: [String],
        answer: String,
        existing: [String],
        needed: Int,
        sourceTokens: Set<String>?,
        enforceQuality: Bool = true
    ) -> [String] {
        guard needed > 0 else { return [] }

        let answerTokens = tokens(answer)
        let band = lengthBand(for: answer)

        var kept: [String] = []
        var seen = existing

        for candidate in candidates {
            let text = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }
            guard text.caseInsensitiveCompare(answer) != .orderedSame else { continue }
            guard !seen.contains(where: { $0.caseInsensitiveCompare(text) == .orderedSame }) else { continue }

            if enforceQuality {
                guard text.count >= band.lower, text.count <= band.upper else { continue }

                // The token rules do not apply when there are no tokens to compare, which
                // is the case for any answer whose words are all under three characters.
                let candidateTokens = tokens(text)
                if !candidateTokens.isEmpty {
                    if !answerTokens.isEmpty,
                       similarity(candidateTokens, answerTokens) >= paraphraseThreshold { continue }
                    if let sourceTokens, candidateTokens.isDisjoint(with: sourceTokens) { continue }
                    if seen.contains(where: { similarity(tokens($0), candidateTokens) >= paraphraseThreshold }) { continue }
                }
            }

            kept.append(text)
            seen.append(text)
            if kept.count == needed { break }
        }
        return kept
    }

    /// Proportional bounds alone collapse for short answers: "ATP" accepts only two to
    /// seven characters, rejecting every real option. The absolute slack keeps the band
    /// usable at that scale and leaves it unchanged for long prose answers.
    nonisolated private static func lengthBand(for answer: String) -> (lower: Int, upper: Int) {
        let length = answer.count
        let lower = min(Double(length) * minLengthRatio, Double(length - absoluteSlack))
        let upper = max(Double(length) * maxLengthRatio, Double(length + absoluteSlack))
        return (max(1, Int(lower)), Int(upper))
    }

    /// Words of three or more characters stand in for a stopword list. A real one would
    /// need to be per-language, and the threshold comparisons are tolerant enough without it.
    nonisolated private static func tokens(_ text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count > 2 }
        )
    }

    nonisolated private static func similarity(_ a: Set<String>, _ b: Set<String>) -> Double {
        let union = a.union(b)
        guard !union.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(union.count)
    }
}

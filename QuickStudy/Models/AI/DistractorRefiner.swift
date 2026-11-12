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

    /// Pass the whole document as `source` at generation time. At quiz time pass nil: a card
    /// only keeps its one-sentence excerpt, and a good confusable term from elsewhere in the
    /// notes shares no words with it.
    nonisolated static func refine(_ candidates: [String], answer: String, source: String?) -> [String] {
        accept(candidates, answer: answer, existing: [], needed: 3, sourceTokens: source.map(tokens))
    }

    /// Other cards' answers, used when the model produced fewer than three usable options.
    /// These legitimately share no vocabulary with this card's source, so the source check
    /// is skipped.
    /// Another card's answer is only a believable option when it is the same kind of thing:
    /// a percentage question offered "a severe fiscal crisis" gives itself away.
    nonisolated static func backfill(_ pool: [String], answer: String, existing: [String], needed: Int) -> [String] {
        accept(pool, answer: answer, existing: existing, needed: needed, sourceTokens: nil, matchesNumericKind: true)
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
        enforceQuality: Bool = true,
        matchesNumericKind: Bool = false
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
                // A full sentence among short phrases, or the reverse, marks itself as wrong.
                guard isSentence(text) == isSentence(answer) else { continue }
                if matchesNumericKind, containsDigit(text) != containsDigit(answer) { continue }

                // The token rules do not apply when there are no tokens to compare, which
                // is the case for any answer whose words are all under three characters.
                let candidateTokens = tokens(text)
                if !candidateTokens.isEmpty {
                    if !answerTokens.isEmpty,
                       similarity(candidateTokens, answerTokens) >= paraphraseThreshold { continue }
                    // "about 97 percent" restates "roughly 97 percent" even though most words differ.
                    let answerNumbers = answerTokens.filter { $0.contains(where: \.isNumber) }
                    if !answerNumbers.isEmpty,
                       candidateTokens.filter({ $0.contains(where: \.isNumber) }) == answerNumbers { continue }
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
    /// Numbers are kept at any length: dropping "97" made "roughly 3 percent" read as a
    /// paraphrase of "roughly 97 percent", so every changed-number distractor was discarded.
    /// Chinese, Japanese and Korean do not separate words the way these rules assume
    /// (no spaces, or particles fused to the word), so their text is compared by character
    /// pairs instead. Whole-word tokens there never overlap, which rejected every distractor
    /// as "not from the source".
    nonisolated private static func tokens(_ text: String) -> Set<String> {
        var result: Set<String> = []
        for word in text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted) where !word.isEmpty {
            var run: [Character] = []
            var runIsUnspaced = false
            func flush() {
                if runIsUnspaced {
                    // A lone character is a whole word here (水, 물), so it still counts.
                    if run.count == 1 { result.insert(String(run)) }
                    for index in run.indices.dropLast() { result.insert(String(run[index...index + 1])) }
                } else if run.count > 2 || run.contains(where: \.isNumber) {
                    result.insert(String(run))
                }
                run.removeAll(keepingCapacity: true)
            }
            for character in word {
                let unspaced = isUnspacedScript(character)
                if unspaced != runIsUnspaced { flush() }
                runIsUnspaced = unspaced
                run.append(character)
            }
            flush()
        }
        return result
    }

    nonisolated private static func isUnspacedScript(_ character: Character) -> Bool {
        guard let scalar = character.unicodeScalars.first else { return false }
        switch scalar.value {
        case 0x3040...0x30FF, 0x3400...0x4DBF, 0x4E00...0x9FFF, 0xAC00...0xD7AF, 0xF900...0xFAFF:
            return true
        default:
            return false
        }
    }

    nonisolated private static func isSentence(_ text: String) -> Bool {
        guard let last = text.last else { return false }
        return ".!?。！？".contains(last) && text.split(separator: " ").count > 3
    }

    nonisolated private static func containsDigit(_ text: String) -> Bool {
        text.contains(where: \.isNumber)
    }

    nonisolated private static func similarity(_ a: Set<String>, _ b: Set<String>) -> Double {
        let union = a.union(b)
        guard !union.isEmpty else { return 0 }
        return Double(a.intersection(b).count) / Double(union.count)
    }
}

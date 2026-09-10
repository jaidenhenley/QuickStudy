//
//  SentenceIndexer.swift
//  QuickStudy
//

import Foundation
import NaturalLanguage

struct IndexedSentence {
    let index: Int
    let text: String
}

/// Numbering the source lets the model return an index instead of a verbatim quote,
/// so the excerpt is always real document text rather than something the model composed.
enum SentenceIndexer {
    static func sentences(in text: String, maxLength: Int) -> [IndexedSentence] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var result: [IndexedSentence] = []
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sentence.isEmpty else { return true }
            for piece in wordSplit(sentence, maxLength: maxLength) {
                result.append(IndexedSentence(index: result.count + 1, text: piece))
            }
            return true
        }
        return result
    }

    /// normalizeOCRLines collapses a whole document to one line when the page is mostly
    /// short fragments, and handwriting OCR often has no terminal punctuation to split on.
    /// Without this floor a single unsplittable unit overflows the context window and
    /// fails the entire import.
    private static func wordSplit(_ sentence: String, maxLength: Int) -> [String] {
        guard sentence.count > maxLength else { return [sentence] }

        var pieces: [String] = []
        var current = ""
        for word in sentence.split(whereSeparator: { $0.isWhitespace }) {
            if !current.isEmpty, current.count + word.count + 1 > maxLength {
                pieces.append(current)
                current = ""
            }
            current += current.isEmpty ? String(word) : " " + word
        }
        if !current.isEmpty { pieces.append(current) }
        return pieces
    }

    static func chunks(of sentences: [IndexedSentence], maxLength: Int) -> [[IndexedSentence]] {
        var chunks: [[IndexedSentence]] = []
        var current: [IndexedSentence] = []
        var length = 0

        for sentence in sentences {
            if !current.isEmpty, length + sentence.text.count > maxLength {
                chunks.append(current)
                current = []
                length = 0
            }
            current.append(sentence)
            length += sentence.text.count
        }

        if !current.isEmpty { chunks.append(current) }
        return chunks
    }
}

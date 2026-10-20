//
//  ContentAnalysis.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation
import NaturalLanguage

struct ContentAnalysis {
    let wordCount: Int
    let estimatedCards: Int
    let language: String?

    static func immediate(for text: String) -> ContentAnalysis {
        let words = text.split { $0.isWhitespace || $0.isNewline }.count
        return ContentAnalysis(
            wordCount: words,
            estimatedCards: max(1, sentenceCount(text)),
            language: detectLanguage(text)
        )
    }

    var estimatedCardsLabel: String {
        estimatedCards == 1 ? "~1 card" : "~\(estimatedCards) cards"
    }

    /// Every engine drafts about one card per sentence of source, so sentences track the
    /// result far better than words did.
    private static func sentenceCount(_ text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        return tokenizer.tokens(for: text.startIndex..<text.endIndex).count
    }

    private static func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let code = recognizer.dominantLanguage else { return nil }
        return Locale.current.localizedString(forLanguageCode: code.rawValue)
    }
}

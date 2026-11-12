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
        let words = SourceLanguage.wordCount(in: text)
        return ContentAnalysis(
            wordCount: words,
            estimatedCards: estimatedCards(forWords: words),
            language: detectLanguage(text)
        )
    }

    var estimatedCardsLabel: String {
        String(localized: "~\(estimatedCards) cards")
    }

    /// Measured against real drafts: 402 words gave 16 cards, 140 gave 6, 37 gave 2. Sentence
    /// counts overshot by more than double, so the estimate follows word count instead.
    private static let wordsPerCard = 25
    private static let maximumEstimate = 60

    private static func estimatedCards(forWords words: Int) -> Int {
        guard words >= wordsPerCard else { return 1 }
        let estimate = Int((Double(words) / Double(wordsPerCard)).rounded())
        return min(max(2, estimate), maximumEstimate)
    }

    private static func detectLanguage(_ text: String) -> String? {
        guard let language = SourceLanguage.dominant(in: text) else { return nil }
        return Locale.current.localizedString(forLanguageCode: language.rawValue)
    }
}

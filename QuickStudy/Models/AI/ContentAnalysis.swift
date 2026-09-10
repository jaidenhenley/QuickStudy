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
    /// The only field needing the model, so it arrives after the others have rendered.
    var contentType: String?

    static func immediate(for text: String) -> ContentAnalysis {
        let words = text.split { $0.isWhitespace || $0.isNewline }.count
        return ContentAnalysis(
            wordCount: words,
            estimatedCards: max(1, words / 30),
            language: detectLanguage(text),
            contentType: nil
        )
    }

    private static func detectLanguage(_ text: String) -> String? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let code = recognizer.dominantLanguage else { return nil }
        return Locale.current.localizedString(forLanguageCode: code.rawValue)
    }
}

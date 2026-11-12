//
//  SourceLanguage.swift
//  QuickStudy
//

import Foundation
import NaturalLanguage

/// Cards are written in the language of the material, not the language of the iPhone.
enum SourceLanguage {
    static func dominant(in text: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(String(text.prefix(4_000)))
        guard let language = recognizer.dominantLanguage, language != .undetermined else { return nil }
        return language
    }

    /// Prompts are written in English, so the language is named in English for the model.
    static func promptName(for text: String) -> String? {
        guard let language = dominant(in: text) else { return nil }
        return Locale(identifier: "en").localizedString(forIdentifier: language.rawValue)
    }

    static func promptRule(for text: String) -> String {
        guard let name = promptName(for: text) else {
            return "Write every card in the same language as the source. Never translate it."
        }
        return "The source is in \(name). Write every question, answer, explanation and wrong answer in \(name). Never translate it."
    }

    /// Whitespace splitting counts a Japanese or Chinese page as one word.
    static func wordCount(in text: String) -> Int {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        var count = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { _, _ in
            count += 1
            return true
        }
        return count
    }
}

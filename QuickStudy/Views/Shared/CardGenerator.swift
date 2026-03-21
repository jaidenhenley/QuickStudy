//
//  CardGenerator.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/25/26.
//

import Foundation

// Responsible for generating flashcards from a document.
struct CardGenerator {
    // MARK: - AI generation

    static func generateAI(from rawText: String) async throws -> [StudyCard] {
#if canImport(FoundationModels)
        let engine = CardGenerationEngine()
        let cards = try await engine.generateCards(from: rawText)
        return cards.map { aiCard in
            StudyCard(question: aiCard.question, answer: aiCard.answer, approved: false)
        }
#else
        throw NSError(
            domain: "FoundationModelsUnavailable",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "FoundationModels is unavailable."]
        )
#endif
    }

    /// Generates plausible but incorrect distractor answers for a flashcard using on-device AI.
    static func generateDistractors(question: String, correctAnswer: String) async throws -> [String] {
#if canImport(FoundationModels)
        let engine = CardGenerationEngine()
        return try await engine.generateDistractors(question: question, correctAnswer: correctAnswer)
#else
        throw NSError(
            domain: "FoundationModelsUnavailable",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "FoundationModels is unavailable."]
        )
#endif
    }
}

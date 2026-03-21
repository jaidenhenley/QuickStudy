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
        let engine = OnDeviceCardGenerationEngine()
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
    static func generateDistractors(
        question: String,
        correctAnswer: String,
        otherAnswers: [String],
        sourceText: String
    ) async throws -> [String] {
#if canImport(FoundationModels)
        let engine = OnDeviceCardGenerationEngine()
        return try await engine.generateDistractors(
            question: question,
            correctAnswer: correctAnswer,
            otherAnswers: otherAnswers,
            sourceText: sourceText
        )
#else
        throw NSError(
            domain: "FoundationModelsUnavailable",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "FoundationModels is unavailable."]
        )
#endif
    }

    /// Generates a complete quiz in one batch AI call, maximizing context for the on-device model.
    /// Returns an array of wrong-answer arrays, one per input card (in the same order).
    static func generateQuiz(
        cards: [(question: String, answer: String)],
        sourceText: String
    ) async throws -> [[String]] {
#if canImport(FoundationModels)
        let engine = OnDeviceCardGenerationEngine()
        let results = try await engine.generateQuiz(cards: cards, sourceText: sourceText)
        return results.map { $0.wrongAnswers }
#else
        throw NSError(
            domain: "FoundationModelsUnavailable",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "FoundationModels is unavailable."]
        )
#endif
    }
}

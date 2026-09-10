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

    static func generateAI(
        from rawText: String,
        document: StudyDocument,
        settings: AISettings
    ) async throws -> [StudyCard] {
        let engine = try AIController.makeGenerator(settings: settings)
        let cards = try await engine.generateCards(from: rawText)
        return cards.map { aiCard in
            StudyCard(
                question: aiCard.question,
                answer: aiCard.answer,
                source: CardSourceLocator.locate(excerpt: aiCard.sourceExcerpt, in: document),
                explanation: aiCard.explanation.isEmpty ? nil : aiCard.explanation,
                distractors: aiCard.distractors
            )
        }
    }

    static func generateTopicCards(
        from rawText: String,
        document: StudyDocument,
        topic: String,
        count: Int,
        settings: AISettings
    ) async throws -> [StudyCard] {
        let engine = try AIController.makeGenerator(settings: settings)
        let cards = try await engine.generateCards(from: rawText, topic: topic, count: count)
        return cards.map { aiCard in
            StudyCard(
                question: aiCard.question,
                answer: aiCard.answer,
                source: CardSourceLocator.locate(excerpt: aiCard.sourceExcerpt, in: document),
                explanation: aiCard.explanation.isEmpty ? nil : aiCard.explanation,
                distractors: aiCard.distractors
            )
        }
    }

}

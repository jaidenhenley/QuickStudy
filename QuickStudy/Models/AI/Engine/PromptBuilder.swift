//
//  PromptBuilder.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/23/26.
//

import Foundation

enum PromptBuilder {
    static func flashcardPrompt(from text: String) -> String {
        """
        Create study flashcards from the source material below.

        Return only JSON in this format:
        {
          "cards": [
            { "question": "string", "answer": "string" }
          ]
        }

        Rules:
        - Only use information explicitly stated in the source material
        - No outside knowledge
        - Each question should test one concept
        - Answers must be short and directly supported by the text
        - Skip unclear content

        Source:
        \(text)
        """
    }

    static func distractorPrompt(
        question: String,
        correctAnswer: String,
        otherAnswers: [String],
        sourceText: String
    ) -> String {
        let contextBlock = otherAnswers.prefix(15).joined(separator: "\n- ")
        let sourceExcerpt = String(sourceText.prefix(1500))

        return """
        Return only JSON in this format:
        {
          "distractorAnswers": ["string", "string", "string"]
        }

        Source:
        \(sourceExcerpt)

        Other answers:
        - \(contextBlock)

        Question: \(question)
        Correct answer: \(correctAnswer)

        Rules:
        - Exactly 3 wrong answers
        - Plausible but incorrect
        - Same style and approximate length as the correct answer
        - Do not restate the correct answer
        """
    }

    static func quizPrompt(
        cards: [(question: String, answer: String)],
        sourceText: String
    ) -> String {
        let sourceExcerpt = String(sourceText.prefix(2000))
        let cardList = cards.enumerated().map {
            "\($0.offset + 1). Q: \($0.element.question)\nA: \($0.element.answer)"
        }.joined(separator: "\n")

        return """
        Return only JSON in this format:
        {
          "questions": [
            { "wrongAnswers": ["string", "string", "string"] }
          ]
        }

        Source:
        \(sourceExcerpt)

        Questions and answers:
        \(cardList)

        Rules:
        - One output entry per input card
        - Exactly 3 wrong answers per question
        - Plausible and on-topic
        - No filler like "None of the above"
        """
    }
}

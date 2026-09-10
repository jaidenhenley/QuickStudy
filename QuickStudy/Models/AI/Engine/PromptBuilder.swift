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
            {
              "question": "string",
              "answer": "string",
              "sourceExcerpt": "string",
              "explanation": "string",
              "distractors": ["string", "string", "string"]
            }
          ]
        }

        Rules:
        - Only use information explicitly stated in the source material
        - No outside knowledge
        - Each question should test one concept
        - Answers must be short and directly supported by the text
        - sourceExcerpt must be copied VERBATIM from the source — the exact sentence the
          card is based on, so it can be located in the original document
        - explanation is one or two sentences saying why the answer is correct, written
          for a learner who just got it wrong
        - distractors are exactly 3 wrong answers for this question. Each must be plausible,
          use terminology from the source material, and match the length and sentence shape
          of the correct answer. Never restate the correct answer. No filler like "None of the above"
        - distractors are exactly 3 wrong answers for this question. Each must be plausible,
          use terminology from the source material, and match the length and sentence shape
          of the correct answer. Never restate the correct answer. No filler like "None of the above"
        - Skip unclear content

        Source:
        \(text)
        """
    }

    static func topicFlashcardPrompt(from text: String, topic: String, count: Int) -> String {
        """
        Create at most \(count) study flashcards about "\(topic)" from the source material below.

        Return only JSON in this format:
        {
          "cards": [
            { "question": "string", "answer": "string" }
          ]
        }

        Rules:
        - Every card must be about "\(topic)"
        - Only use information explicitly stated in the source material
        - No outside knowledge
        - Each question should test one concept
        - Answers must be short and directly supported by the text
        - If the source does not cover "\(topic)" in enough depth, return fewer cards rather than inventing facts

        Source:
        \(text)
        """
    }
}

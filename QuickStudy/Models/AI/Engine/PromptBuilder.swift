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

        \(jsonShape)

        Rules:
        - Create one card for every distinct fact, definition, or step in the source.
          Cover the whole passage rather than only its opening
        \(sharedRules)
        - Skip unclear content

        Source:
        \(text)
        """
    }

    static func topicFlashcardPrompt(from text: String, topic: String, count: Int) -> String {
        """
        Create at most \(count) study flashcards about "\(topic)" from the source material below.

        \(jsonShape)

        Rules:
        - Every card must be about "\(topic)"
        \(sharedRules)
        - If the source does not cover "\(topic)" in enough depth, return fewer cards rather
          than inventing facts

        Source:
        \(text)
        """
    }

    private static let jsonShape = """
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
    """

    /// Shared so the two prompts cannot drift apart. The topic prompt previously asked for
    /// only question and answer, which left API-generated topic cards unable to build a
    /// multiple-choice question.
    private static let sharedRules = """
    - Only use information explicitly stated in the source material
    - No outside knowledge
    - Each question should test one concept
    - Answers must be short and directly supported by the text
    - sourceExcerpt must be copied VERBATIM from the source — the exact sentence the
      card is based on, so it can be located in the original document
    - explanation is one or two sentences saying why the answer is correct, written
      for a learner who just got it wrong
    - distractors are exactly 3 wrong answers for this question, one of each kind: one that
      swaps in a different term from the source that learners confuse with the right one,
      one that states something the source supports but that does not answer this question,
      and one that keeps the right shape while changing a single name, number, or step.
      Each must use terminology from the source material and match the length and sentence
      shape of the correct answer. Never restate the correct answer. No filler like
      "None of the above"
    """
}

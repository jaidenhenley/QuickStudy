//
//  File.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/11/26.
//

//
//  QuizQuestion.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/21/26.
//

import Foundation

// Represents a single multiple-choice quiz question built from flashcards.
struct QuizQuestion: Identifiable, Hashable {
    let id: UUID
    var prompt: String
    var choices: [String]
    var correctIndex: Int
    var explanation: String
    var sourceStartLine: Int
    var sourceEndLine: Int

    init(id: UUID = UUID(), prompt: String, choices: [String], correctIndex: Int, explanation: String, sourceStartLine: Int, sourceEndLine: Int) {
        self.id = id
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = choices.indices.contains(correctIndex) ? correctIndex : 0
        self.explanation = explanation
        self.sourceStartLine = sourceStartLine
        self.sourceEndLine = sourceEndLine
    }
}

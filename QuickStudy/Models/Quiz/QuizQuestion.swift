//
//  QuizQuestion.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/21/26.
//

import Foundation

// A single multiple-choice question, built from a flashcard for one session.
struct QuizQuestion: Identifiable, Hashable {
    let id: UUID
    let cardID: UUID
    let setID: UUID
    var prompt: String
    var choices: [String]
    var correctIndex: Int
    var explanation: String
    var source: CardSource?
    var setTitle: String
    var boxBefore: Int

    init(
        id: UUID = UUID(),
        cardID: UUID,
        setID: UUID,
        prompt: String,
        choices: [String],
        correctIndex: Int,
        explanation: String,
        source: CardSource? = nil,
        setTitle: String,
        boxBefore: Int
    ) {
        self.id = id
        self.cardID = cardID
        self.setID = setID
        self.prompt = prompt
        self.choices = choices
        self.correctIndex = choices.indices.contains(correctIndex) ? correctIndex : 0
        self.explanation = explanation
        self.source = source
        self.setTitle = setTitle
        self.boxBefore = boxBefore
    }
}

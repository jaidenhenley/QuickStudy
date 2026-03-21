//
//  CardGenerating.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/20/26.
//

import Foundation

protocol CardGenerating {
    func generateCards(from text: String) async throws -> [AIFlashcard]
    func generateDistractors(question: String, correctAnswer: String, otherAnswers: [String], sourceText: String) async throws -> [String]
    func generateQuiz(cards: [(question: String, answer: String)], sourceText: String) async throws -> [AIQuizQuestionModel]
}

//
//  APICardGenerationEngine.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/20/26.
//

import Foundation

struct APICardGenerationEngine: CardGenerating {
    
    func generateCards(from text: String) async throws -> [AIFlashcard] {
        let url = URL(string: "")
    }
    
    func generateDistractors(question: String, correctAnswer: String, otherAnswers: [String], sourceText: String) async throws -> [String] {
        <#code#>
    }
    
    func generateQuiz(cards: [(question: String, answer: String)], sourceText: String) async throws -> [AIQuizQuestionModel] {
        <#code#>
    }
    
    let apiKey: String
    
    
}

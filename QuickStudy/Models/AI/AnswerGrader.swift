//
//  AnswerGrader.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

enum AnswerGrader {
    /// Exact matches never reach the model — instant, and removes the largest source
    /// of false negatives. Rejecting a correct paraphrase is the costliest failure here,
    /// so every fallback below leans toward accepting.
    static func grade(question: String, expected: String, submitted: String) async -> AnswerGrade {
        let normalizedExpected = normalized(expected)
        let normalizedSubmitted = normalized(submitted)

        guard !normalizedSubmitted.isEmpty else {
            return AnswerGrade(isCorrect: false, rationale: "No answer given.")
        }
        if normalizedExpected == normalizedSubmitted {
            return AnswerGrade(isCorrect: true, rationale: "Exact match.")
        }

        #if canImport(FoundationModels)
        let engine = OnDeviceCardGenerationEngine()
        if let grade = try? await engine.grade(question: question, expected: expected, submitted: submitted) {
            return grade
        }
        #endif

        let lenient = normalizedSubmitted.contains(normalizedExpected)
            || normalizedExpected.contains(normalizedSubmitted)
        return AnswerGrade(
            isCorrect: lenient,
            rationale: lenient ? "Your answer covers the key idea." : "That doesn't match the expected answer."
        )
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

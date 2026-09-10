//
//  AnswerGrading.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

struct AnswerGrade {
    let isCorrect: Bool
    let rationale: String
}

/// Separate from `CardGenerating` because grading is on-device only — a typed answer
/// never leaves the phone, even when generation is configured to use an API.
protocol AnswerGrading {
    func grade(question: String, expected: String, submitted: String) async throws -> AnswerGrade
}

//
//  CardGenerationEngine.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

// This file isolates FoundationModels to keep the rest of the app compile-safe.
// The framework is iOS 26+ only, so availability gating is centralized here.
// Wrapping with canImport prevents build failures when the module is missing.
// The rest of the app talks to simple Swift models only.

struct CardGenerationEngine {
    func generateCards(from text: String) async throws -> [AIFlashcard] {
        let session = LanguageModelSession()
        let prompt = """
        Analyze the following scanned text and extract the most important concepts.
        Create a set of high quality flashcards for a student.

        TEXT:
        \(text)
        """
        let response = try await session.respond(to: prompt, generating: AIFLashcardSetModel.self)
        return response.content.cards.map { AIFlashcard(question: $0.question, answer: $0.answer) }
    }

    func generateDistractors(question: String, correctAnswer: String) async throws -> [String] {
        let session = LanguageModelSession()
        let prompt = """
        Given this flashcard:
        Question: \(question)
        Correct Answer: \(correctAnswer)

        Generate 3 plausible but incorrect distractor answers. \
        Each distractor should be similar in length and style to the correct answer.
        """
        let response = try await session.respond(to: prompt, generating: AIAnswerModel.self)
        return response.content.distractorAnswers
    }

    func repairOCR(lines: [String], candidates: [[String]]) async throws -> String {
        let prompt = buildContextPrompt(lines: lines, candidates: candidates, startIndex: 1)
        let session = LanguageModelSession()
        let response = try await session.respond(to: prompt, generating: AIOCRRepairModel.self)
        return response.content.correctedText
    }

    private func buildContextPrompt(lines: [String], candidates: [[String]], startIndex: Int) -> String {
        var candidateBlock: [String] = []
        for (offset, line) in lines.enumerated() {
            let lineNumber = startIndex + offset
            candidateBlock.append("Line \(lineNumber):")
            let lineCandidatesSource = offset < candidates.count ? candidates[offset] : []
            var lineCandidates = lineCandidatesSource
            if !lineCandidates.contains(line) {
                lineCandidates.insert(line, at: 0)
            }
            for candidate in lineCandidates.prefix(5) {
                candidateBlock.append("- \(candidate)")
            }
        }

        return """
        You are an OCR repair assistant. Fix misread or incomplete words using surrounding context.
        Preserve the original line breaks and return exactly \(lines.count) lines.
        Keep the same word count per line; only replace words, do not reorder them.
        Do not add new information. If unsure, keep the original line.
        Do not repeat lines or output duplicates unless they appear in the candidates.
        Return only the corrected text.

        OCR LINE CANDIDATES:
        \(candidateBlock.joined(separator: "\n"))
        """
    }
}

// MARK: - FoundationModels types

@Generable
private struct AIFlashcardModel: Codable {
    @Guide(description: "A clear, concise study question")
    let question: String

    @Guide(description: "A short, accurate answer")
    let answer: String
}
@Generable
private struct AIAnswerModel: Codable {
    @Guide(description: "Generate 3 distractor answers that are similar in length and style to the real answer but are clearly incorrect")
    let distractorAnswers: [String]
}

@Generable
private struct AIFLashcardSetModel: Codable {
    let cards: [AIFlashcardModel]
}

@Generable
private struct AIOCRRepairModel: Codable {
    @Guide(description: "Corrected OCR text with original line breaks preserved")
    let correctedText: String
}
#endif

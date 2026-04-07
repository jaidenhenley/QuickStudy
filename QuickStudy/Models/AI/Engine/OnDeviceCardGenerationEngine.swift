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

struct OnDeviceCardGenerationEngine: CardGenerating {
    
    func generateCards(from text: String) async throws -> [AIFlashcard] {
        let chunks = chunkText(text, maxLength: 2500)
        var allCards: [AIFlashcard] = []
        
        for chunk in chunks {
            let session = LanguageModelSession()
            let prompt = """
            You are an expert educator creating high-quality study flashcards.

            SOURCE MATERIAL:
            \(chunk)

            QUESTION RULES:
            - Each question must test exactly one fact, not multiple facts at once
            - If a concept has multiple parts, create one card per part
            - Prefer narrow, specific questions over broad ones
            - Never ask a question that requires listing or comparing more than two things

            QUESTION TYPES:
            - DEFINITION: What is X?
            - CAUSE_EFFECT: Why does X happen? / What results from X?
            - COMPARE: How does X differ from Y? (two things only, one difference)
            - PROCESS: What happens at step X?
            - APPLICATION: In what situation would X apply?

            ANSWER RULES:
            - Write answers in your own words, do not copy from the source
            - Each answer must directly and completely resolve its question in as few sentences as needed

            Only create cards from information explicitly in the source. Skip anything unclear.
            """
            let response = try await session.respond(to: prompt, generating: AIFLashcardSetModel.self)
            let cards = response.content.cards.map { AIFlashcard(question: $0.question, answer: $0.answer) }
            allCards.append(contentsOf: cards)
        }
        return allCards

    }
    
    func chunkText(_ text: String, maxLength: Int) -> [String] {
        var chunks: [String] = []
        var current = ""
        
        for paragraph in text.components(separatedBy: "\n\n") {
            if current.count + paragraph.count > maxLength {
                if !current.isEmpty {
                    chunks.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                current = paragraph
            } else {
                current += (current.isEmpty ? "" : "\n\n") + paragraph
            }
        }
        
        if !current.isEmpty {
            chunks.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return chunks
    }
    
    func generateDistractors(
        question: String,
        correctAnswer: String,
        otherAnswers: [String],
        sourceText: String
    ) async throws -> [String] {
        for _ in 0..<2 {
            let session = LanguageModelSession()
            let contextBlock = otherAnswers.prefix(15).joined(separator: "\n- ")
            let sourceExcerpt = String(sourceText.prefix(1500))
            
            let prompt = """
        You are an educator creating multiple-choice answer options to test student understanding.
        
        SOURCE MATERIAL:
        \(sourceExcerpt)
        
        OTHER ANSWERS FROM THIS STUDY SET:
        - \(contextBlock)
        
        QUESTION: \(question)
        CORRECT ANSWER: \(correctAnswer)
        
        Generate 3 incorrect answer options that test whether the student understood the concept.
        
        CONTENT RULES:
        - Each incorrect option must use real terminology and concepts from the source material
        - Use related but incorrect details: for example, attribute a property to the wrong concept, \
        or use a number or name from a different part of the material
        - Each option should address the same topic as the correct answer
        
        FORMATTING RULES:
        - Match the length and sentence structure of the correct answer
        - If the correct answer is a short phrase, each option must be a short phrase
        - If the correct answer is a full sentence, each option must be a full sentence
        
        ACCURACY RULES:
        - Do not restate or rephrase the correct answer
        - Do not include the correct answer within an incorrect option
        - Each incorrect option must be factually wrong for this question
        """
            let response = try await session.respond(to: prompt, generating: AIAnswerModel.self)
            let distractors = response.content.distractorAnswers
            if isValidDistractors(distractors) {
                return distractors
            }
        }
        throw CardGenerationError.invalidDistractors
    }
    
    func generateQuiz(
        cards: [(question: String, answer: String)],
        sourceText: String
    ) async throws -> [AIQuizQuestionModel] {
        var results: [AIQuizQuestionModel] = []

        for card in cards {
            let otherAnswers = cards
                .filter { $0.question != card.question }
                .map { $0.answer }

            if let distractors = try? await generateDistractors(
                question: card.question,
                correctAnswer: card.answer,
                otherAnswers: otherAnswers,
                sourceText: sourceText
            ) {
                results.append(AIQuizQuestionModel(wrongAnswers: distractors))
            }
        }

        return results
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
    // MARK: Filler Detection
    
    private let fillerPhrases = [
        "none of the above",
        "all of the above",
        "not covered",
        "not mentioned",
        "none of these",
        "all of these",
        "not applicable"
    ]
    
    func containsFiller(_ text: String) -> Bool {
        let lower = text.lowercased()
        return fillerPhrases.contains { lower.contains($0) }
    }
    
    func isValidDistractors(_ distractors: [String]) -> Bool {
        guard distractors.count >= 3 else { return false }
        return !distractors.contains { containsFiller($0) }
    }
    
}

// MARK: - FoundationModels types

@Generable
private struct AIFlashcardModel: Codable {
    @Guide(description: "A clear, concise study question that tests recall of a single concept. Do not include the answer in the question. Avoid yes/no questions.")
    let question: String

    @Guide(description: "A concise answer in 1-2 sentences. Synthesize the key point in your own words. Do not copy sentences from the source material.")
    let answer: String
}

@Generable
private struct AIAnswerModel: Codable {
    @Guide(description: "Exactly 3 incorrect answer options. Each must be about the same topic as the question. Do not use facts from unrelated concepts. Each option must be plausible for this specific question but factually wrong.")
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

@Generable
struct AIQuizQuestionModel: Codable {
    @Guide(description: "The 3 wrong answers for this question. Each must be plausible, match the style and length of the correct answer, and use real terminology from the source material.")
    let wrongAnswers: [String]
}

#endif

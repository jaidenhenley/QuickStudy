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

struct OnDeviceCardGenerationEngine {
    func generateCards(from text: String) async throws -> [AIFlashcard] {
        let session = LanguageModelSession()
        let prompt = """
        You are creating study flashcards from a student's notes.

        Source material:
        \(text)

        Rules:
        - Only create flashcards from information explicitly stated in the source material
        - Do not infer or add outside knowledge
        - Questions should test recall of a single concept
        - Answers must be directly supported by the text
        - Skip any text that is unclear or illegible
        - Use the student's own terminology from their notes

        TEXT:
        \(text)
        """
        let response = try await session.respond(to: prompt, generating: AIFLashcardSetModel.self)
        return response.content.cards.map { AIFlashcard(question: $0.question, answer: $0.answer) }
    }

    func generateDistractors(
        question: String,
        correctAnswer: String,
        otherAnswers: [String],
        sourceText: String
    ) async throws -> [String] {
        let session = LanguageModelSession()

        // Give the model the full topic context so distractors are on-topic
        let contextBlock = otherAnswers.prefix(15).joined(separator: "\n- ")
        let sourceExcerpt = String(sourceText.prefix(1500))

        let prompt = """
        You are a quiz master creating challenging multiple-choice questions from study notes. \
        Your goal is to make distractors that are HARD to distinguish from the real answer.

        SOURCE MATERIAL:
        \(sourceExcerpt)

        OTHER ANSWERS FROM THIS STUDY SET:
        - \(contextBlock)

        TARGET QUESTION: \(question)
        CORRECT ANSWER: \(correctAnswer)

        Generate 3 wrong answers. Follow these rules strictly:

        DIFFICULTY RULES:
        - Each distractor must be a factual-sounding statement about the same topic
        - Mix in real terminology and concepts from the source material
        - Make distractors that a student who only skimmed the notes would pick
        - Subtly alter key details: swap names, change numbers, reverse cause/effect, \
        or attribute a property to the wrong concept

        FORMATTING RULES:
        - Match the exact length, tone, and sentence structure of the correct answer
        - If the correct answer is a short phrase, distractors must be short phrases
        - If the correct answer is a full sentence, distractors must be full sentences

        CRITICAL RULES:
        - NEVER include the answer to the question inside the distractor text
        - NEVER rephrase or restate the correct answer
        - Each distractor must be clearly wrong if you know the material, but tempting if you don't
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

    /// Generates a complete quiz in a single AI call, giving the model full context across all cards.
    /// This maximizes the on-device model's ability to create challenging, topic-aware distractors.
    func generateQuiz(
        cards: [(question: String, answer: String)],
        sourceText: String
    ) async throws -> [AIQuizQuestionModel] {
        let session = LanguageModelSession()

        let sourceExcerpt = String(sourceText.prefix(2000))

        // Build a numbered list of all Q/A pairs
        var cardList = ""
        for (i, card) in cards.enumerated() {
            cardList += "\(i + 1). Q: \(card.question)\n   A: \(card.answer)\n"
        }

        let prompt = """
        You are creating a multiple-choice quiz from study notes. \
        You have ALL the questions and answers below. \
        For each question, generate exactly 3 wrong answers.

        SOURCE MATERIAL:
        \(sourceExcerpt)

        ALL QUESTIONS AND CORRECT ANSWERS:
        \(cardList)

        RULES:
        - For each question, create 3 plausible but wrong answers
        - Use facts, terms, and concepts from the source material in your wrong answers
        - Swap names, change numbers, reverse cause and effect, or attribute details to the wrong concept
        - Wrong answers should match the length and style of the correct answer
        - Never repeat the correct answer as a wrong answer
        - Never use generic filler like "None of the above"
        - Make wrong answers that a student who skimmed the notes would pick
        - You may reuse real facts from OTHER questions as wrong answers for THIS question
        """
        let response = try await session.respond(to: prompt, generating: AIQuizModel.self)
        return response.content.questions
    }
}

// MARK: - FoundationModels types

@Generable
private struct AIFlashcardModel: Codable {
    @Guide(description: "A clear, concise study question that tests recall of a single concept. Do not include the answer in the question. Avoid yes/no questions.")
    let question: String

    @Guide(description: "A short, accurate answer in 1-2 sentences. Use plain language a student would understand.")
    let answer: String
}

@Generable
private struct AIAnswerModel: Codable {
    @Guide(description: "Exactly 3 wrong answers that are hard to distinguish from the real answer. Each must match the length and sentence structure of the correct answer. Use real terminology from the source material but alter key details. Never restate the correct answer. Never include the answer in the distractor.")
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

@Generable
struct AIQuizModel: Codable {
    @Guide(description: "One entry per question, in the same order as the input. Each entry contains exactly 3 wrong answers.")
    let questions: [AIQuizQuestionModel]
}
#endif

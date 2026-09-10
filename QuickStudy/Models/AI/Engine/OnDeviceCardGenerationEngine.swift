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
        let chunks = chunkText(text, maxLength: 1200)
        var allCards: [AIFlashcard] = []

        for chunk in chunks {
            let session = LanguageModelSession()
            let target = max(4, chunk.count / 180)
            let prompt = """
            You are an expert educator creating high-quality study flashcards.

            SOURCE MATERIAL:
            \(chunk)

            COVERAGE:
            - Create roughly \(target) cards from this passage
            - Every distinct fact, definition, or step in the source deserves its own card
            - Do not stop early: work through the passage from beginning to end

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
            let cards = response.content.cards.map { AIFlashcard(
                question: $0.question,
                answer: $0.answer,
                sourceExcerpt: $0.sourceExcerpt,
                explanation: $0.explanation,
                distractors: $0.distractors
            ) }
            allCards.append(contentsOf: cards)
        }
        return allCards

    }
    
    /// Single pass rather than the chunked loop above: a topic drill wants `count`
    /// cards total, not `count` per chunk.
    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard] {
        let session = LanguageModelSession()
        let prompt = """
        You are an expert educator creating study flashcards about a single topic.

        TOPIC: \(topic)

        SOURCE MATERIAL:
        \(String(text.prefix(2500)))

        Create at most \(count) flashcards, every one of them about "\(topic)".

        QUESTION RULES:
        - Each question must test exactly one fact about \(topic)
        - Prefer narrow, specific questions over broad ones
        - Do not repeat a question the source already answers in the same words

        ANSWER RULES:
        - Write answers in your own words, do not copy from the source
        - Each answer must directly and completely resolve its question

        Only use information explicitly in the source. If the source says little about \(topic),
        return fewer cards rather than inventing facts.
        """
        let response = try await session.respond(to: prompt, generating: AIFLashcardSetModel.self)
        return response.content.cards
            .prefix(count)
            .map { AIFlashcard(
                question: $0.question,
                answer: $0.answer,
                sourceExcerpt: $0.sourceExcerpt,
                explanation: $0.explanation,
                distractors: $0.distractors
            ) }
    }

    /// Accumulates whole lines up to the limit. The previous version split on blank
    /// lines, which normalisation strips — so it never chunked at all.
    func chunkText(_ text: String, maxLength: Int) -> [String] {
        var chunks: [String] = []
        var current = ""

        for line in text.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            if !current.isEmpty, current.count + trimmed.count + 1 > maxLength {
                chunks.append(current)
                current = trimmed
            } else {
                current += current.isEmpty ? trimmed : "\n" + trimmed
            }
        }

        if !current.isEmpty { chunks.append(current) }
        return chunks
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
    
    
    
    
}

// MARK: - FoundationModels types

@Generable
private struct AIFlashcardModel: Codable {
    @Guide(description: "A clear, concise study question that tests recall of a single concept. Do not include the answer in the question. Avoid yes/no questions.")
    let question: String

    @Guide(description: "A concise answer in 1-2 sentences. Synthesize the key point in your own words. Do not copy sentences from the source material.")
    let answer: String

    @Guide(description: "The exact sentence or sentences from the SOURCE MATERIAL this card is based on, copied verbatim with no rewording. Used to locate the card's origin in the original document.")
    let sourceExcerpt: String

    @Guide(description: "One or two sentences explaining why the answer is correct, written for a learner who just answered incorrectly. Explain the concept, do not restate the answer.")
    let explanation: String

    @Guide(description: "Exactly 3 incorrect answers for this question. Each must be plausible, use real terminology from the source material, and match the length and sentence structure of the correct answer. Never restate the correct answer. No filler like 'None of the above'.")
    let distractors: [String]
}

@Generable
private struct AIFLashcardSetModel: Codable {
    @Guide(description: "One flashcard for every distinct fact, definition, or step in the source material. Cover the whole passage rather than only its opening.")
    let cards: [AIFlashcardModel]
}

@Generable
private struct AIOCRRepairModel: Codable {
    @Guide(description: "Corrected OCR text with original line breaks preserved")
    let correctedText: String
}

#endif

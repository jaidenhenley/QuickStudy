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

    private static let chunkLength = 1200

    // Instructions outrank prompt content, so scanned text cannot steer generation.
    // This does not reduce tokens: a fresh session per chunk re-sends them either way.
    private static let cardInstructions = Instructions("""
    You are an expert educator creating high-quality study flashcards.

    COVERAGE:
    - Every distinct fact, definition, or step in the source deserves its own card
    - Work through the source from first sentence to last, do not stop early

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

    WRONG ANSWER RULES:
    - Write exactly three wrong answers per card, one of each kind
    - A wrong answer must be defensible to someone who half-learned the material
    - Build every wrong answer from terms that appear in the source sentences
    - Match the length and sentence shape of the correct answer
    - Never state the correct answer in different words

    Only create cards from information explicitly in the source. Skip anything unclear.
    """)

    // Not greedy sampling: Regenerate has to produce a different draft on a second run.
    private static let options = GenerationOptions(temperature: 0.3)

    /// Model load dominates first-run latency, so the import flow warms it while the
    /// camera or file picker is still open.
    static func prewarm() {
        guard OnDeviceModelAvailability.isAvailable else { return }
        LanguageModelSession(instructions: cardInstructions).prewarm()
    }

    func generateCards(from text: String) async throws -> [AIFlashcard] {
        try OnDeviceModelAvailability.check()

        let sentences = SentenceIndexer.sentences(in: text, maxLength: Self.chunkLength)
        guard !sentences.isEmpty else { return [] }

        var allCards: [AIFlashcard] = []
        for chunk in SentenceIndexer.chunks(of: sentences, maxLength: Self.chunkLength) {
            allCards += try await cards(for: chunk)
        }
        return allCards
    }

    /// Single pass rather than the chunked loop above: a topic drill wants `count`
    /// cards total, not `count` per chunk.
    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard] {
        try OnDeviceModelAvailability.check()

        let sentences = SentenceIndexer.sentences(
            in: String(text.prefix(2500)),
            maxLength: Self.chunkLength
        )
        guard !sentences.isEmpty else { return [] }

        let instructions = Instructions("""
        You are an expert educator creating study flashcards about a single topic.

        Every card must be about "\(topic)".

        QUESTION RULES:
        - Each question must test exactly one fact about \(topic)
        - Prefer narrow, specific questions over broad ones
        - Do not repeat a question the source already answers in the same words

        ANSWER RULES:
        - Write answers in your own words, do not copy from the source
        - Each answer must directly and completely resolve its question

        WRONG ANSWER RULES:
        - Write exactly three wrong answers per card, one of each kind
        - Build every wrong answer from terms that appear in the source sentences
        - Match the length and sentence shape of the correct answer
        - Never state the correct answer in different words

        Only use information explicitly in the source. If the source says little about
        \(topic), return fewer cards rather than inventing facts.
        """)

        let session = LanguageModelSession(instructions: instructions)
        let prompt = """
        SOURCE SENTENCES:
        \(Self.numbered(sentences))

        Create at most \(count) flashcards about "\(topic)".
        """

        do {
            let response = try await session.respond(
                to: prompt,
                generating: AIFLashcardSetModel.self,
                options: Self.options
            )
            return response.content.cards
                .prefix(count)
                .compactMap { flashcard($0, in: sentences) }
        } catch let error as LanguageModelSession.GenerationError {
            throw Self.mapped(error)
        }
    }

    /// On overflow the chunk is halved and retried. A fresh session per chunk is
    /// deliberate: a shared session accumulates transcript and overflows a 4K window
    /// after a chunk or two.
    private func cards(for chunk: [IndexedSentence], depth: Int = 0) async throws -> [AIFlashcard] {
        guard !chunk.isEmpty else { return [] }

        let session = LanguageModelSession(instructions: Self.cardInstructions)
        let target = max(2, chunk.count / 2)
        let prompt = """
        SOURCE SENTENCES:
        \(Self.numbered(chunk))

        Create roughly \(target) cards covering these sentences from first to last.
        """

        do {
            let response = try await session.respond(
                to: prompt,
                generating: AIFLashcardSetModel.self,
                options: Self.options
            )
            return response.content.cards.compactMap { flashcard($0, in: chunk) }
        } catch let error as LanguageModelSession.GenerationError {
            if case .exceededContextWindowSize = error, depth < 2, chunk.count > 1 {
                let middle = chunk.count / 2
                return try await cards(for: Array(chunk[..<middle]), depth: depth + 1)
                     + (try await cards(for: Array(chunk[middle...]), depth: depth + 1))
            }
            throw Self.mapped(error)
        }
    }

    /// Numbering restarts at 1 per chunk. Global numbering asked the model for values
    /// like "sentence 214", which it gets wrong far more often than "sentence 4".
    private static func numbered(_ sentences: [IndexedSentence]) -> String {
        sentences.enumerated()
            .map { "\($0.offset + 1). \($0.element.text)" }
            .joined(separator: "\n")
    }

    // Only the cases confirmed on this SDK are matched by name. A case name that does
    // not exist is a build failure, not a runtime fallthrough.
    private static func mapped(_ error: LanguageModelSession.GenerationError) -> CardGenerationError {
        switch error {
        case .exceededContextWindowSize: return .contextWindowExceeded
        case .guardrailViolation: return .guardrailViolation
        case .unsupportedLanguageOrLocale: return .unsupportedLanguage
        default: return .generationFailed
        }
    }

    /// The model returns a position within this chunk; the sentence text is looked up
    /// here so CardSourceLocator always matches. An out-of-range position drops the
    /// source rather than asserting a wrong one.
    private func flashcard(_ model: AIFlashcardModel, in chunk: [IndexedSentence]) -> AIFlashcard? {
        let question = model.question.trimmingCharacters(in: .whitespacesAndNewlines)
        let answer = model.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !answer.isEmpty else { return nil }

        let position = model.sourceSentence - 1
        let excerpt = chunk.indices.contains(position) ? chunk[position].text : ""

        return AIFlashcard(
            question: question,
            answer: answer,
            sourceExcerpt: excerpt,
            explanation: model.explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            distractors: DistractorRefiner.refine(
                model.distractors.map(\.text),
                answer: answer,
                source: chunk.map(\.text).joined(separator: " ")
            )
        )
    }

    func repairOCR(lines: [String], candidates: [[String]]) async throws -> String {
        try OnDeviceModelAvailability.check()

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

// Naming the kind of wrongness is what improves distractor quality. Asked for three
// free-form strings the model produces near-duplicates; asked for one of each kind it
// has to reach for three different failure modes a learner really has.
@Generable
private enum DistractorKind: String, Codable {
    case commonConfusion
    case partiallyTrue
    case wrongDetail
}

@Generable
private struct AIDistractorModel: Codable {
    @Guide(description: "How this option is wrong. commonConfusion swaps in a different term from the source that learners mix up with the right one. partiallyTrue states something the source supports but that does not answer this question. wrongDetail keeps the right shape and changes one name, number, or step.")
    let kind: DistractorKind

    @Guide(description: "The wrong answer itself. It must read like a real answer to the question, use terms that appear in the source sentences, and match the length and sentence shape of the correct answer. Never state the correct answer in different words.")
    let text: String
}

@Generable
private struct AIFlashcardModel: Codable {
    @Guide(description: "A clear, concise study question that tests recall of a single concept. Do not include the answer in the question. Avoid yes/no questions.")
    let question: String

    @Guide(description: "A concise answer in 1-2 sentences. Synthesize the key point in your own words. Do not copy sentences from the source material.")
    let answer: String

    @Guide(description: "The number of the single SOURCE SENTENCE this card is based on. Use only a number shown in the numbered list.")
    let sourceSentence: Int

    @Guide(description: "One or two sentences explaining why the answer is correct, written for a learner who just answered incorrectly. Explain the concept, do not restate the answer.")
    let explanation: String

    @Guide(description: "Exactly three wrong answers, one commonConfusion, one partiallyTrue, and one wrongDetail. No filler like 'None of the above'.", .count(3))
    let distractors: [AIDistractorModel]
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

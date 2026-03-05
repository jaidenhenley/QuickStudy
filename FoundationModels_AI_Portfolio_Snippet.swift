// On-Device AI with FoundationModels - QuickStudy
// Uses Apple's FoundationModels framework for structured on-device flashcard generation
// with compile-time safety and graceful fallback when AI unavailable

import Foundation

#if canImport(FoundationModels)
import FoundationModels

// Isolates FoundationModels to a single file with canImport guard for build safety
// across different iOS versions and hardware capabilities
struct AICardGenerator {

    // Generates flashcards from text using on-device AI with structured output
    // via FoundationModels @Generable macro for type-safe generation
    func generateCards(from text: String) async throws -> [Flashcard] {
        let session = LanguageModelSession()

        let prompt = """
        Analyze the following scanned text and extract the most important concepts.
        Create a set of high quality flashcards for a student.

        TEXT:
        \(text)
        """

        // Structured generation ensures type-safe output matching FlashcardSetModel schema
        let response = try await session.respond(to: prompt, generating: FlashcardSetModel.self)

        return response.content.cards.map {
            Flashcard(question: $0.question, answer: $0.answer, approved: false)
        }
    }

    // Repairs OCR errors using AI context correction with multiple candidate strings per line
    // Chunks large documents (8-20 lines) to respect model limits while preserving context
    func repairOCR(lines: [String], candidates: [[String]]) async throws -> String {
        let prompt = buildContextPrompt(lines: lines, candidates: candidates)
        let session = LanguageModelSession()

        let response = try await session.respond(to: prompt, generating: OCRRepairModel.self)
        return response.content.correctedText
    }

    // Builds prompt with top 5 candidate strings per line for context-aware correction
    private func buildContextPrompt(lines: [String], candidates: [[String]]) -> String {
        var candidateBlock: [String] = []

        for (index, line) in lines.enumerated() {
            candidateBlock.append("Line \(index + 1):")

            var lineCandidates = index < candidates.count ? candidates[index] : []
            if !lineCandidates.contains(line) {
                lineCandidates.insert(line, at: 0)
            }

            // Include top 5 candidate interpretations per line
            for candidate in lineCandidates.prefix(5) {
                candidateBlock.append("- \(candidate)")
            }
        }

        return """
        You are an OCR repair assistant. Fix misread or incomplete words using surrounding context.
        Preserve the original line breaks and return exactly \(lines.count) lines.
        Keep the same word count per line; only replace words, do not reorder them.
        Do not add new information. If unsure, keep the original line.

        OCR LINE CANDIDATES:
        \(candidateBlock.joined(separator: "\n"))
        """
    }
}

// FoundationModels @Generable types define the structure for AI output
// Using @Guide macro to provide semantic hints to the language model

@Generable
private struct FlashcardModel: Codable {
    @Guide(description: "A clear, concise study question")
    let question: String

    @Guide(description: "A short, accurate answer")
    let answer: String
}

@Generable
private struct FlashcardSetModel: Codable {
    let cards: [FlashcardModel]
}

@Generable
private struct OCRRepairModel: Codable {
    @Guide(description: "Corrected OCR text with original line breaks preserved")
    let correctedText: String
}

#endif

// Public interface that works regardless of FoundationModels availability
struct CardGenerationService {

    // Attempts AI generation, falls back to deterministic splitter if unavailable
    func generateCards(from text: String) async throws -> [Flashcard] {
#if canImport(FoundationModels)
        do {
            let generator = AICardGenerator()
            return try await generator.generateCards(from: text)
        } catch {
            // Fallback to rule-based generation on AI failure
            return generateFallbackCards(from: text)
        }
#else
        return generateFallbackCards(from: text)
#endif
    }

    // Deterministic fallback: splits text into cards using pattern matching
    // Looks for ":", "is", "are" patterns to create question/answer pairs
    private func generateFallbackCards(from text: String) -> [Flashcard] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return lines.prefix(12).map { line in
            let (question, answer) = extractQuestionAnswer(from: line)
            return Flashcard(question: question, answer: answer, approved: false)
        }
    }

    // Pattern-based extraction for fallback mode
    private func extractQuestionAnswer(from line: String) -> (question: String, answer: String) {
        // Check for colon separator (e.g., "Swift: A programming language")
        if let range = line.range(of: ":") {
            let left = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let right = line[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            return (left.isEmpty ? "Explain this concept" : String(left), right.isEmpty ? line : String(right))
        }

        // Check for "is" pattern (e.g., "Swift is a programming language")
        if let range = line.range(of: " is ") {
            let subject = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            return ("What is \(subject)?", line)
        }

        // Default: use first 6 words as question prefix
        let words = line.split(whereSeparator: { $0.isWhitespace }).prefix(6)
        let prefix = words.joined(separator: " ")
        return ("Explain: \(prefix)", line)
    }
}

// Supporting type
struct Flashcard {
    let question: String
    let answer: String
    let approved: Bool
}

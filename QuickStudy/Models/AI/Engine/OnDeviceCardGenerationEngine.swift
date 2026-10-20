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
    let countsAgainstAllowance = true
    var sourceChunkLimit: Int? { Self.chunkLength }
    var skippedSourceSections: Int { skipped.count }
    let expectedSeconds: Double = 6
    let provenance = GenerationProvenance(engine: .onDevice, model: "Apple Intelligence")
    var progress: GenerationProgress?
    let skipped = SkippedSectionCounter()

    private static let chunkLength = 1200
    private static let topicSourceLength = 2500

    /// Model load dominates first-run latency, so the import flow warms it while the
    /// camera or file picker is still open.
    static func prewarm() {
        guard OnDeviceModelAvailability.isAvailable else { return }
        LanguageModelSession(instructions: CardDraftingCore.cardInstructions).prewarm()
    }

    func generateCards(from text: String) async throws -> [AIFlashcard] {
        try OnDeviceModelAvailability.check()
        return try await core.cards(from: text)
    }

    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard] {
        try OnDeviceModelAvailability.check()
        return try await core.topicCards(from: text, topic: topic, count: count)
    }

    private var core: CardDraftingCore {
        CardDraftingCore(
            chunkLength: Self.chunkLength,
            topicSourceLength: Self.topicSourceLength,
            progress: progress,
            skipped: skipped
        ) { LanguageModelSession(instructions: $0) }
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

@Generable
private struct AIOCRRepairModel: Codable {
    @Guide(description: "Corrected OCR text with original line breaks preserved")
    let correctedText: String
}

#endif

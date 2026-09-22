//
//  HostedCardGenerationEngine.swift
//  QuickStudy
//

import Foundation

struct HostedCardGenerationEngine: CardGenerating {
    private struct GenerateRequest: Encodable {
        let challenge: String
        let text: String
        let transaction: String?
        let topic: String?
        let count: Int?
    }

    let api: HostedAPI
    let transaction: String?
    let onRemaining: @MainActor @Sendable (Int) -> Void
    let countsAgainstAllowance = false
    let sourceChunkLimit: Int? = nil
    let expectedSeconds: Double = 22

    func generateCards(from text: String) async throws -> [AIFlashcard] {
        try await request(text: text, topic: nil, count: nil)
    }

    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard] {
        Array(try await request(text: text, topic: topic, count: count).prefix(count))
    }

    private func request(text: String, topic: String?, count: Int?) async throws -> [AIFlashcard] {
        do {
            return try await attempt(text: text, topic: topic, count: count)
        } catch CardGenerationError.attestationKeyUnknown {
            try await AppAttestClient.shared.resetRegistration()
            return try await attempt(text: text, topic: topic, count: count)
        }
    }

    private func attempt(text: String, topic: String?, count: Int?) async throws -> [AIFlashcard] {
        let challenge = try await api.challenge()
        let body = try JSONEncoder().encode(
            GenerateRequest(challenge: challenge, text: text, transaction: transaction, topic: topic, count: count)
        )
        // The exact bytes that are signed are the bytes that are sent; the server hashes them the same way.
        let signature = HostedAPI.developmentBypassToken == nil
            ? try await AppAttestClient.shared.sign(body, using: api)
            : nil
        let response = try await api.generate(signedBody: body, signature: signature)
        await onRemaining(response.remaining)

        return response.cards.map {
            AIFlashcard(
                question: $0.question,
                answer: $0.answer,
                sourceExcerpt: $0.sourceExcerpt,
                explanation: $0.explanation,
                distractors: DistractorRefiner.refine($0.distractors, answer: $0.answer, source: text)
            )
        }
    }
}

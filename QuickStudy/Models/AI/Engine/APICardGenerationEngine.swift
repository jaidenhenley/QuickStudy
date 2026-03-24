//
//  APICardGenerationEngine.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/20/26.
//

import Foundation

struct APICardGenerationEngine: CardGenerating {
    let endpoint: URL
    let model: String
    let apiKey: String
    let apiFormat: APIFormat

    init(endpoint: URL, model: String, apiKey: String, apiFormat: APIFormat = .openAI) {
        self.endpoint = endpoint
        self.model = model
        self.apiKey = apiKey
        self.apiFormat = apiFormat
    }

    func generateCards(from text: String) async throws -> [AIFlashcard] {
        let prompt = PromptBuilder.flashcardPrompt(from: text)
        let jsonString = try await sendPrompt(prompt)
        let decoded = try decodeJSON(AIFlashcardSetResponse.self, from: jsonString)
        return decoded.cards.map { AIFlashcard(question: $0.question, answer: $0.answer) }
    }

    func generateDistractors(
        question: String,
        correctAnswer: String,
        otherAnswers: [String],
        sourceText: String
    ) async throws -> [String] {
        let prompt = PromptBuilder.distractorPrompt(
            question: question,
            correctAnswer: correctAnswer,
            otherAnswers: otherAnswers,
            sourceText: sourceText
        )

        let jsonString = try await sendPrompt(prompt)
        let decoded = try decodeJSON(AIDistractorResponse.self, from: jsonString)
        return decoded.distractorAnswers
    }

    func generateQuiz(
        cards: [(question: String, answer: String)],
        sourceText: String
    ) async throws -> [AIQuizQuestionModel] {
        let prompt = PromptBuilder.quizPrompt(cards: cards, sourceText: sourceText)
        let jsonString = try await sendPrompt(prompt)
        let decoded = try decodeJSON(APIQuizResponse.self, from: jsonString)
        return decoded.questions.map { AIQuizQuestionModel(wrongAnswers: $0.wrongAnswers) }
    }
}

private extension APICardGenerationEngine {
    func sendPrompt(_ prompt: String) async throws -> String {
        let systemMessage = "Return only valid JSON. No markdown. No explanation."

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        switch apiFormat {
        case .openAI:
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            let body = OpenAIChatRequest(
                model: model,
                messages: [
                    .init(role: "system", content: systemMessage),
                    .init(role: "user", content: prompt)
                ],
                temperature: 0.3
            )
            request.httpBody = try JSONEncoder().encode(body)

        case .anthropic:
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let body = AnthropicMessagesRequest(
                model: model,
                max_tokens: 4096,
                system: systemMessage,
                messages: [
                    .init(role: "user", content: prompt)
                ],
                temperature: 0.3
            )
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw CardGenerationError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw CardGenerationError.badStatusCode(http.statusCode)
        }

        let content: String
        switch apiFormat {
        case .openAI:
            let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
            guard let text = decoded.choices.first?.message.content else {
                throw CardGenerationError.unsupportedProviderResponse
            }
            content = text

        case .anthropic:
            let decoded = try JSONDecoder().decode(AnthropicMessagesResponse.self, from: data)
            guard let text = decoded.content.first?.text else {
                throw CardGenerationError.unsupportedProviderResponse
            }
            content = text
        }

        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CardGenerationError.unsupportedProviderResponse
        }

        return content
    }

    func decodeJSON<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
        let cleaned = cleanJSONString(string)
        
        guard let data = string.data(using: .utf8) else {
            throw CardGenerationError.decodingFailed
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CardGenerationError.decodingFailed
        }
    }
    
    func cleanJSONString(_ string: String) -> String {
        var cleaned = string.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        if cleaned.hasPrefix("```json") {
            cleaned = cleaned.replacingOccurrences(of: "```json", with: "")
        }
        
        if cleaned.hasPrefix("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned
        
    }
}

// MARK: - Shared

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - OpenAI Chat Completions

private struct OpenAIChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct OpenAIChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ResponseMessage
    }

    struct ResponseMessage: Decodable {
        let content: String
    }
}

// MARK: - Anthropic Messages API

private struct AnthropicMessagesRequest: Encodable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct AnthropicMessagesResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
}

private struct AIFlashcardSetResponse: Decodable {
    let cards: [APIFlashcard]
}

private struct APIFlashcard: Decodable {
    let question: String
    let answer: String
}

private struct AIDistractorResponse: Decodable {
    let distractorAnswers: [String]
}

private struct APIQuizResponse: Decodable {
    let questions: [APIQuizQuestion]
}

private struct APIQuizQuestion: Decodable {
    let wrongAnswers: [String]
}

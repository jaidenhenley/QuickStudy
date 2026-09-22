//
//  HostedAPI.swift
//  QuickStudy
//

import Foundation

struct HostedAPI {
    struct Signature {
        let keyID: String
        let assertion: String
    }

    struct HostedCard: Decodable {
        let question: String
        let answer: String
        let sourceExcerpt: String
        let explanation: String
        let distractors: [String]
    }

    struct GenerateResponse: Decodable {
        let cards: [HostedCard]
        let remaining: Int
    }

    private struct ChallengeResponse: Decodable {
        let challenge: String
    }

    private struct RegisterRequest: Encodable {
        let keyId: String
        let attestation: String
        let challenge: String
    }

    private struct ServerError: Decodable {
        struct Body: Decodable {
            let code: String
            let message: String
        }
        let error: Body
    }

    static let production = URL(string: "https://quickstudy-api-production.jaidenhenley.workers.dev")!

    let baseURL: URL

    /// Simulator has no App Attest, so DEBUG simulator builds may present the dev Worker's
    /// bypass token instead. Both values come from the run scheme's environment and never
    /// exist in a device build.
    static var developmentBypassToken: String? {
        #if DEBUG && targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["QS_DEV_TOKEN"]
        #else
        return nil
        #endif
    }

    static func configured() -> HostedAPI {
        #if DEBUG
        if let override = ProcessInfo.processInfo.environment["QS_API_URL"], let url = URL(string: override) {
            return HostedAPI(baseURL: url)
        }
        #endif
        return HostedAPI(baseURL: production)
    }

    func challenge() async throws -> String {
        let data = try await send(path: "/attest/challenge", body: Data("{}".utf8), headers: [:])
        return try decode(ChallengeResponse.self, from: data).challenge
    }

    func register(keyID: String, attestation: String, challenge: String) async throws {
        let body = try JSONEncoder().encode(RegisterRequest(keyId: keyID, attestation: attestation, challenge: challenge))
        _ = try await send(path: "/attest/register", body: body, headers: [:])
    }

    func generate(signedBody: Data, signature: Signature?) async throws -> GenerateResponse {
        var headers: [String: String] = [:]
        if let signature {
            headers["X-Key-Id"] = signature.keyID
            headers["X-Assertion"] = signature.assertion
        } else if let token = Self.developmentBypassToken {
            headers["X-Dev-Token"] = token
        } else {
            throw CardGenerationError.attestationUnavailable
        }
        let data = try await send(path: "/generate", body: signedBody, headers: headers)
        return try decode(GenerateResponse.self, from: data)
    }

    private func send(path: String, body: Data, headers: [String: String]) async throws -> Data {
        var request = URLRequest(url: baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CardGenerationError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw CardGenerationError.invalidResponse }
        guard (200...299).contains(http.statusCode) else {
            if let server = try? JSONDecoder().decode(ServerError.self, from: data) {
                throw Self.error(code: server.error.code, message: server.error.message)
            }
            throw CardGenerationError.badStatusCode(http.statusCode)
        }
        return data
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw CardGenerationError.decodingFailed
        }
    }

    static func error(code: String, message: String) -> CardGenerationError {
        switch code {
        case "unauthorized":
            return .attestationFailed(message)
        case "not_subscribed":
            return .notSubscribed(message)
        case "quota_exhausted":
            return .hostedQuotaExhausted(message)
        case "input_too_large":
            return .hostedInputTooLarge(message)
        default:
            return .hostedUnavailable(message)
        }
    }
}

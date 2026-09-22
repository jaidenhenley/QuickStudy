//
//  AppAttestClient.swift
//  QuickStudy
//

import CryptoKit
import DeviceCheck
import Foundation

actor AppAttestClient {
    static let shared = AppAttestClient()

    private let service = DCAppAttestService.shared

    var isSupported: Bool { service.isSupported }

    /// The server no longer knows this key — its record was rotated or lost. Keychain
    /// survives app deletion, so without this the device would send the orphaned key
    /// forever and could never recover, even after a reinstall.
    func resetRegistration() throws {
        try KeychainManager.delete(account: .appAttestKeyID)
    }

    func sign(_ body: Data, using api: HostedAPI) async throws -> HostedAPI.Signature {
        let hash = Data(SHA256.hash(data: body))
        let keyID = try await registeredKeyID(using: api)
        do {
            return try await assertion(for: hash, keyID: keyID)
        } catch let error as DCError where error.code == .invalidKey {
            // Apple revoked the key (restore, OS reinstall). Register a fresh one once.
            try KeychainManager.delete(account: .appAttestKeyID)
            let fresh = try await registeredKeyID(using: api)
            return try await assertion(for: hash, keyID: fresh)
        }
    }

    private func assertion(for hash: Data, keyID: String) async throws -> HostedAPI.Signature {
        let assertion = try await service.generateAssertion(keyID, clientDataHash: hash)
        return HostedAPI.Signature(keyID: keyID, assertion: assertion.base64EncodedString())
    }

    private func registeredKeyID(using api: HostedAPI) async throws -> String {
        if let existing = KeychainManager.load(account: .appAttestKeyID) { return existing }
        guard service.isSupported else { throw CardGenerationError.attestationUnavailable }

        let keyID: String
        let attestation: Data
        let challenge = try await api.challenge()
        do {
            keyID = try await service.generateKey()
            attestation = try await service.attestKey(keyID, clientDataHash: Data(SHA256.hash(data: Data(challenge.utf8))))
        } catch {
            throw CardGenerationError.attestationFailed(error.localizedDescription)
        }
        try await api.register(keyID: keyID, attestation: attestation.base64EncodedString(), challenge: challenge)
        // Stored only once the server accepted it, so a failed registration retries from scratch.
        try KeychainManager.save(keyID, account: .appAttestKeyID)
        return keyID
    }
}

//
//  KeychainManager.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/23/26.
//

import Foundation
import Security

enum KeychainManager {
    enum Account: String {
        case externalAPIKey = "external-api-key"
        case appAttestKeyID = "app-attest-key-id"
        case generationAllowance = "generation-allowance"
    }

    private static let service = "com.jaidenhenley.quickstudy"

    static func saveAPIKey(_ key: String) throws {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            try deleteAPIKey()
            return
        }
        try save(trimmed, account: .externalAPIKey)
    }

    static func loadAPIKey() -> String? {
        load(account: .externalAPIKey)
    }

    static func deleteAPIKey() throws {
        try delete(account: .externalAPIKey)
    }

    /// Update-then-add rather than delete-then-add: a failed write must never
    /// destroy the value that was already stored.
    static func save(_ value: String, account: Account) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]
        let data = Data(value.utf8)

        let updateStatus = SecItemUpdate(
            query as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else {
            throw CardGenerationError.keychainError(updateStatus)
        }

        let attributes = query.merging([kSecValueData as String: data]) { _, new in new }
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw CardGenerationError.keychainError(addStatus)
        }
    }

    static func load(account: Account) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    #if DEBUG
    static func deleteAllItems() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CardGenerationError.keychainError(status)
        }
    }
    #endif

    static func delete(account: Account) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw CardGenerationError.keychainError(status)
        }
    }
}

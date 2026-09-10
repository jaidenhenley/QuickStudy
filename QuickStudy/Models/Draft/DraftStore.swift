//
//  DraftStore.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.henley.jaiden.QuickStudy",
    category: "DraftStore"
)

@MainActor
@Observable
final class DraftStore {
    private(set) var pending: DraftSet?

    private var url: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = documents.first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("PendingDraft.json")
    }

    init() {
        load()
    }

    func set(_ draft: DraftSet?) {
        pending = draft
        persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        pending = try? decoder.decode(DraftSet.self, from: data)
    }

    private func persist() {
        guard let pending else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(pending).write(to: url, options: [.atomic])
        } catch {
            logger.error("Failed to persist draft: \(error.localizedDescription)")
        }
    }
}

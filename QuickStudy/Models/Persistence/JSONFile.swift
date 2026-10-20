//
//  JSONFile.swift
//  QuickStudy
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.henley.jaiden.QuickStudy",
    category: "JSONFile"
)

enum PersistenceIssue: Equatable {
    /// The file couldn't be decoded. It was moved aside, so the store starts empty and
    /// saving can't destroy the original.
    case corrupt
    /// The file exists but couldn't be read or moved. Saving stays off for this launch,
    /// because writing would replace data that may still be intact.
    case unreadable
}

enum JSONFileLoad<Value> {
    case missing
    case loaded(Value)
    case failed(PersistenceIssue)
}

struct JSONFile {
    let url: URL

    init(named name: String) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = documents.first ?? FileManager.default.temporaryDirectory
        url = directory.appendingPathComponent(name)
    }

    func load<Value: Decodable>(_ type: Value.Type) -> JSONFileLoad<Value> {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .missing
        } catch {
            logger.error("Failed to read \(url.lastPathComponent): \(error.localizedDescription)")
            return .failed(.unreadable)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return .loaded(try decoder.decode(Value.self, from: data))
        } catch {
            logger.error("Failed to decode \(url.lastPathComponent): \(error.localizedDescription)")
            return .failed(moveAside() ? .corrupt : .unreadable)
        }
    }

    func save<Value: Encodable>(_ value: Value, outputFormatting: JSONEncoder.OutputFormatting = []) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = outputFormatting
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(value).write(to: url, options: [.atomic])
    }

    func remove() throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        }
    }

    private func moveAside() -> Bool {
        let stamp = Int(Date().timeIntervalSince1970)
        let backup = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
        do {
            try FileManager.default.moveItem(at: url, to: backup)
            return true
        } catch {
            logger.error("Failed to move aside \(url.lastPathComponent): \(error.localizedDescription)")
            return false
        }
    }
}

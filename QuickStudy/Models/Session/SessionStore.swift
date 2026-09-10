//
//  SessionStore.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.henley.jaiden.QuickStudy",
    category: "SessionStore"
)

@MainActor
@Observable
final class SessionStore {
    private(set) var sessions: [StudySession] = []

    /// Six months covers the week strip, longest-streak, and year-scale stats
    /// without the file growing without bound.
    private let retentionDays = 180

    private var url: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = documents.first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("Sessions.json")
    }

    init() {
        load()
    }

    func record(_ session: StudySession) {
        sessions.append(session)
        prune()
        save()
    }

    func sessions(on day: Date, calendar: Calendar = .current) -> [StudySession] {
        sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
    }

    func cardsStudied(on day: Date, calendar: Calendar = .current) -> Int {
        sessions(on: day, calendar: calendar).reduce(0) { $0 + $1.cardCount }
    }

    func studiedDays(calendar: Calendar = .current) -> Set<Date> {
        Set(sessions.filter { $0.endedAt != nil }.map { calendar.startOfDay(for: $0.startedAt) })
    }

    private func prune() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) else { return }
        sessions.removeAll { $0.startedAt < cutoff }
    }

    private func load() {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            sessions = try decoder.decode([StudySession].self, from: data)
        } catch {
            sessions = []
        }
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(sessions).write(to: url, options: [.atomic])
        } catch {
            logger.error("Failed to save sessions: \(error.localizedDescription)")
        }
    }
}

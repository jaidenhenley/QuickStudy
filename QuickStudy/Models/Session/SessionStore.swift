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
    private(set) var loadIssue: PersistenceIssue?
    var isLoadIssuePresented = false

    /// Six months covers the week strip, longest-streak, and year-scale stats
    /// without the file growing without bound.
    private let retentionDays = 180

    private let file = JSONFile(named: "Sessions.json")

    var loadIssueMessage: String {
        switch loadIssue {
        case .corrupt:
            "Your study history couldn't be read, so streaks and stats start fresh. A copy of the original was kept on this iPhone."
        case .unreadable:
            "Your study history couldn't be opened right now. Sessions won't be saved until you restart QuickStudy."
        case nil:
            ""
        }
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
        switch file.load([StudySession].self) {
        case .loaded(let stored):
            sessions = stored
        case .missing:
            sessions = []
        case .failed(let issue):
            sessions = []
            loadIssue = issue
            isLoadIssuePresented = true
        }
    }

    private func save() {
        guard loadIssue != .unreadable else { return }
        do {
            try file.save(sessions)
        } catch {
            logger.error("Failed to save sessions: \(error.localizedDescription)")
        }
    }
}

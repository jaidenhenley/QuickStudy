//
//  LibraryViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

@MainActor
@Observable
final class LibraryViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case due
        case inProgress
        case mastered

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:
                return "All"
            case .due:
                return "Due"
            case .inProgress:
                return "In progress"
            case .mastered:
                return "Mastered"
            }
        }
    }

    var searchText = ""
    var filter: Filter = .all
    var isManualOnly = false

    /// `AICapability` reads the Keychain, so this is refreshed on appear and on a
    /// mode change rather than evaluated from a view body.
    func refreshCapability(settings: AISettings) {
        isManualOnly = AICapability.state(for: settings) == .unsupportedDevice
    }

    func sets(from all: [StudySet], now: Date = Date(), calendar: Calendar = .current) -> [StudySet] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = query.isEmpty
            ? all
            : all.filter { $0.title.localizedCaseInsensitiveContains(query) }

        let filtered = searched.filter { set in
            switch filter {
            case .all:
                return true
            case .due:
                return set.dueCount(asOf: now, calendar: calendar) > 0
            case .inProgress:
                return set.masteryState == .inProgress
            case .mastered:
                return set.masteryState == .mastered
            }
        }

        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
}

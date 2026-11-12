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
    enum StatusCard: Equatable {
        case drafting(ImportCoordinator.DraftingStatus)
        case failed(ImportFailure)
        case ready(DraftSet)

        var kind: String {
            switch self {
            case .drafting: "drafting"
            case .failed: "failed"
            case .ready: "ready"
            }
        }

        static func == (lhs: StatusCard, rhs: StatusCard) -> Bool {
            switch (lhs, rhs) {
            case (.drafting(let a), .drafting(let b)): a == b
            case (.failed(let a), .failed(let b)): a.id == b.id
            case (.ready(let a), .ready(let b)): a.id == b.id
            default: false
            }
        }
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case due
        case inProgress
        case mastered

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:
                return String(localized: "libraryFilter.all", defaultValue: "All", comment: "Library filter chip: every set.")
            case .due:
                return String(localized: "libraryFilter.due", defaultValue: "Due", comment: "Library filter chip: sets with cards due today.")
            case .inProgress:
                return String(localized: "libraryFilter.inProgress", defaultValue: "In progress", comment: "Library filter chip: sets being learned, not yet mastered.")
            case .mastered:
                return String(localized: "libraryFilter.mastered", defaultValue: "Mastered", comment: "Library filter chip: sets whose every card is mastered.")
            }
        }
    }

    var searchText = ""
    var filter: Filter = .all

    static func statusCard(
        drafting: ImportCoordinator.DraftingStatus?,
        failure: ImportFailure?,
        draft: DraftSet?
    ) -> StatusCard? {
        if let drafting { return .drafting(drafting) }
        if let failure { return .failed(failure) }
        if let draft { return .ready(draft) }
        return nil
    }

    /// Cancelling keeps nothing that was read, so the message says the import starts over.
    static var cancelDraftingMessage: String {
        String(localized: "Nothing read so far will be kept. To draft these cards later, import it again.")
    }

    static func readyTitle(for draft: DraftSet) -> String {
        String(localized: "\(draft.title) is ready")
    }

    static func readyDetail(for draft: DraftSet) -> String {
        let count = draft.cards.count
        guard draft.pageCount > 1 else { return String(localized: "\(count) cards drafted") }
        return String(localized: "\(count) cards drafted from \(draft.pageCount) pages")
    }

    static func label(for recovery: ImportFailure.Recovery, in failure: ImportFailure) -> String {
        switch recovery {
        case .tryAgain: String(localized: "Try Again")
        case .pasteText: failure.pasteRecoveryLabel
        case .typeCards: String(localized: "Type Cards")
        }
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

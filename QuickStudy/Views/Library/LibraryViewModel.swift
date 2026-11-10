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

    static func readyTitle(for draft: DraftSet) -> String {
        "\(draft.title) is ready"
    }

    static func readyDetail(for draft: DraftSet) -> String {
        let count = draft.cards.count
        let cards = "\(count) \(count == 1 ? "card" : "cards") drafted"
        guard draft.pageCount > 1 else { return cards }
        return "\(cards) from \(draft.pageCount) pages"
    }

    static func label(for recovery: ImportFailure.Recovery, in failure: ImportFailure) -> String {
        switch recovery {
        case .tryAgain: "Try Again"
        case .pasteText: failure.pasteRecoveryLabel
        case .typeCards: "Type Cards"
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

//
//  SaveDraftViewModel.swift
//  QuickStudy
//

import Foundation

@MainActor
@Observable
final class SaveDraftViewModel {
    enum Destination: Hashable {
        case newSet
        case existingSet
    }

    struct ExistingSet: Identifiable {
        let id: UUID
        let title: String
        let cardCount: Int

        var countLabel: String {
            cardCount == 1 ? "1 card" : "\(cardCount) cards"
        }
    }

    var destination: Destination = .newSet
    var name: String
    var selectedSetID: UUID?

    let existingSets: [ExistingSet]
    private let draft: DraftSet
    private let cards: [StudyCard]

    init(draft: DraftSet, cards: [StudyCard], savedSets: [StudySet]) {
        self.draft = draft
        self.cards = cards
        name = draft.title
        existingSets = savedSets
            .filter { !$0.isDemo && $0.sourceType != .demo }
            .map { ExistingSet(id: $0.id, title: $0.title, cardCount: $0.cards.count) }
        selectedSetID = existingSets.first?.id
    }

    var title: String {
        cards.count == 1 ? "Save 1 Card" : "Save \(cards.count) Cards"
    }

    var canAddToExisting: Bool { !existingSets.isEmpty }

    var canSave: Bool {
        guard !cards.isEmpty else { return false }
        switch destination {
        case .newSet: return true
        case .existingSet: return selectedSet != nil
        }
    }

    var addFooter: String {
        guard let selectedSet else { return "" }
        let count = cards.count == 1 ? "1 card" : "\(cards.count) cards"
        return "\(count) will be added to \(selectedSet.title)."
    }

    private var selectedSet: ExistingSet? {
        existingSets.first { $0.id == selectedSetID }
    }

    /// Clearing the name falls back to the title generation suggested rather than
    /// saving a set with no name.
    func save(to studyViewModel: StudyViewModel, analytics: AnalyticsRecorder) {
        switch destination {
        case .newSet:
            var committed = draft
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            committed.title = trimmed.isEmpty ? draft.title : trimmed
            committed.cards = cards
            studyViewModel.savedSets.insert(committed.committed(), at: 0)
            studyViewModel.saveSavedSets()
            analytics.record(.setCreated)
        case .existingSet:
            guard let selectedSet else { return }
            studyViewModel.addCards(cards, toSetWithID: selectedSet.id)
        }
    }
}

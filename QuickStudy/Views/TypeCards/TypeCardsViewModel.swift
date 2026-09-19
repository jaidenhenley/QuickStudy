//
//  TypeCardsViewModel.swift
//  QuickStudy
//

import Foundation

@MainActor
@Observable
final class TypeCardsViewModel {
    struct Entry: Identifiable, Equatable {
        let id = UUID()
        var term = ""
        var definition = ""

        var isComplete: Bool {
            !term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var title = ""
    var entries: [Entry] = [Entry(), Entry(), Entry()]

    var completeEntries: [Entry] {
        entries.filter(\.isComplete)
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !completeEntries.isEmpty
    }

    var saveLabel: String {
        let count = completeEntries.count
        return count == 1 ? "Save 1 card" : "Save \(count) cards"
    }

    /// The quiz builds wrong answers from a set's other answers, so a set of three or
    /// fewer has to borrow them from elsewhere in the library and reads as weaker.
    var wantsMoreCards: Bool {
        completeEntries.count < 4
    }

    func addEntry() {
        entries.append(Entry())
    }

    func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        if entries.isEmpty { entries = [Entry()] }
    }

    func makeSet() -> StudySet {
        let cleaned = completeEntries.map {
            (
                term: $0.term.trimmingCharacters(in: .whitespacesAndNewlines),
                definition: $0.definition.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        let setTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return StudySet(
            title: setTitle,
            document: StudyDocument(
                title: setTitle,
                lines: cleaned.flatMap { [$0.term, $0.definition] }
            ),
            cards: cleaned.map { StudyCard(question: $0.term, answer: $0.definition) },
            sourceType: .manual
        )
    }
}

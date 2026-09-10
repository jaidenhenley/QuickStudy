//
//  StatsViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

@MainActor
@Observable
final class StatsViewModel {
    struct ToughCard: Identifiable {
        let id: UUID
        let question: String
        let setTitle: String
        let missCount: Int
    }

    struct SetProgress: Identifiable {
        let id: UUID
        let title: String
        let progress: Double
        let mastery: StudySet.MasteryState
    }

    var streak = 0
    var setCount = 0
    var scheduledCards = 0
    var masteredCards = 0
    var dueToday = 0
    var overallProgress: Double = 0
    var toughest: [ToughCard] = []
    var setProgress: [SetProgress] = []

    var hasData: Bool { scheduledCards > 0 }

    func update(from sets: [StudySet], now: Date = Date(), calendar: Calendar = .current) {
        streak = StreakStore.count
        setCount = sets.count

        let scheduled = sets.flatMap(\.cards)
        scheduledCards = scheduled.count
        masteredCards = scheduled.filter(\.isMastered).count
        dueToday = scheduled.filter { $0.isDue(asOf: now, calendar: calendar) }.count
        overallProgress = scheduled.isEmpty
            ? 0
            : scheduled.reduce(0) { $0 + $1.progress } / Double(scheduled.count)

        toughest = sets
            .flatMap { set in
                set.cards
                    .filter { $0.missCount > 0 }
                    .map { ToughCard(id: $0.id, question: $0.question, setTitle: set.title, missCount: $0.missCount) }
            }
            .sorted { $0.missCount > $1.missCount }
            .prefix(3)
            .map { $0 }

        setProgress = sets
            .filter { !$0.cards.isEmpty }
            .map { SetProgress(id: $0.id, title: $0.title, progress: $0.progress, mastery: $0.masteryState) }
            .sorted { $0.progress > $1.progress }
    }
}

//
//  TodayViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation

@MainActor
@Observable
class TodayViewModel {
    struct WeakestCardInfo {
        let question: String
        let missCount: Int
        let setID: UUID
    }

    struct UpNextEntry: Identifiable {
        let id: UUID
        let title: String
        let dueDate: Date
        let cardCount: Int
        let dayLabel: String
    }

    struct SessionSetCount: Identifiable {
        let id: UUID
        let title: String
        let cardCount: Int
    }

    var streakCount: Int = 0
    var todayCardCount: Int = 0
    var estimatedMin: Int = 0
    var weakestCard: WeakestCardInfo? = nil
    var upNext: [UpNextEntry] = []
    var sessionBreakdown: [SessionSetCount] = []
    var hasReviewableCards: Bool = false
    var generationsRemaining: Int = GenerationAllowance.remaining
    let generationsLimit: Int = GenerationAllowance.monthlyLimit

    private let defaults = UserDefaults.standard
    private let streakKey = "qs_streakCount"
    private let lastStudiedKey = "qs_lastStudiedDate"

    init() {
        loadStreak()
    }

    // MARK: Streak

    private func loadStreak() {
        streakCount = defaults.integer(forKey: streakKey)
    }

    func recordStudySession() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults.object(forKey: lastStudiedKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            guard let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day else { return }
            if diff == 1 {
                streakCount += 1
            } else if diff > 1 {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }
        defaults.set(streakCount, forKey: streakKey)
        defaults.set(Date(), forKey: lastStudiedKey)
    }

    // MARK: - Derived

    func updateFromStudy(
        _ studyViewModel: StudyViewModel,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let sets = studyViewModel.savedSets
        hasReviewableCards = sets.contains { !$0.reviewableCards.isEmpty }
        generationsRemaining = GenerationAllowance.remaining
        computeTodaySession(from: sets, now: now, calendar: calendar)
        computeWeakestCard(from: sets)
        computeUpNext(from: sets, now: now, calendar: calendar)
    }

    private func computeTodaySession(from sets: [StudySet], now: Date, calendar: Calendar) {
        let due = sets
            .flatMap(\.reviewableCards)
            .filter { $0.isDue(asOf: now, calendar: calendar) }
        todayCardCount = due.count
        estimatedMin = due.isEmpty ? 0 : max(1, Int(Double(due.count) * 0.5))

        sessionBreakdown = sets.compactMap { set in
            let count = set.dueCount(asOf: now, calendar: calendar)
            guard count > 0 else { return nil }
            return SessionSetCount(id: set.id, title: set.title, cardCount: count)
        }
        .sorted { $0.cardCount > $1.cardCount }
    }

    private func computeWeakestCard(from sets: [StudySet]) {
        let missed = sets.flatMap { set in
            set.reviewableCards
                .filter { $0.missCount > 0 }
                .map { (card: $0, setID: set.id) }
        }
        guard let worst = missed.max(by: { $0.card.missCount < $1.card.missCount }) else {
            weakestCard = nil
            return
        }
        weakestCard = WeakestCardInfo(
            question: worst.card.question,
            missCount: worst.card.missCount,
            setID: worst.setID
        )
    }

    private func computeUpNext(from sets: [StudySet], now: Date, calendar: Calendar) {
        upNext = sets.compactMap { set in
            guard let next = set.nextDueDate(after: now, calendar: calendar) else { return nil }
            let count = set.cardsDue(on: next, calendar: calendar)
            guard count > 0 else { return nil }
            return UpNextEntry(
                id: set.id,
                title: set.title,
                dueDate: next,
                cardCount: count,
                dayLabel: Self.dayLabel(for: next, now: now, calendar: calendar)
            )
        }
        .sorted { $0.dueDate < $1.dueDate }
    }

    private static func dayLabel(for date: Date, now: Date, calendar: Calendar) -> String {
        if calendar.isDateInTomorrow(date) { return "Tomorrow" }
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: now),
            to: calendar.startOfDay(for: date)
        ).day ?? 0
        if days < 7 {
            return date.formatted(.dateTime.weekday(.wide))
        }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

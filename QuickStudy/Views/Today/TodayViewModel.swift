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

    struct GenerationSuggestion {
        let setID: UUID
        let topic: String
        let sourceTitle: String
        let engineLabel: String
        let cardCount: Int
    }

    var streakCount: Int = 0
    var todayCardCount: Int = 0
    var estimatedMin: Int = 0
    var weakestCard: WeakestCardInfo? = nil
    var upNext: [UpNextEntry] = []
    var sessionBreakdown: [SessionSetCount] = []
    var suggestion: GenerationSuggestion? = nil
    var hasReviewableCards: Bool = false
    var generationsRemaining: Int = GenerationAllowance.remaining
    let generationsLimit: Int = GenerationAllowance.monthlyLimit

    // MARK: Streak

    // MARK: - Derived

    func updateFromStudy(
        _ studyViewModel: StudyViewModel,
        sessions: SessionStore,
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        let sets = studyViewModel.savedSets
        hasReviewableCards = sets.contains { !$0.cards.isEmpty }
        generationsRemaining = GenerationAllowance.remaining
        streakCount = StreakCalculator.summary(
            studiedDays: sessions.studiedDays(calendar: calendar),
            frozenDays: StreakStore.frozenDays,
            now: now,
            calendar: calendar
        ).current
        computeTodaySession(from: sets, now: now, calendar: calendar)
        computeWeakestCard(from: sets)
        computeUpNext(from: sets, now: now, calendar: calendar)
        computeSuggestion(from: sets, mode: studyViewModel.aiSettings.mode)
    }

    private func computeSuggestion(from sets: [StudySet], mode: CardGenerationMode) {
        guard let weakest = weakestCard,
              let set = sets.first(where: { $0.id == weakest.setID }) else {
            suggestion = nil
            return
        }
        suggestion = GenerationSuggestion(
            setID: set.id,
            topic: Self.topic(from: weakest.question),
            sourceTitle: set.title,
            engineLabel: mode == .onDevice ? "on-device" : "API",
            cardCount: 3
        )
    }

    /// Longest stems first, so "what is the X" does not match "what is" and leave "the X".
    private static let questionStems = [
        "what is the", "what is a", "what is an", "what is",
        "what are the", "what are", "what does the", "what does", "what do",
        "when should you use", "when does", "when do",
        "how does the", "how does", "how do",
        "why does", "why do", "which", "define", "explain"
    ]

    private static func topic(from question: String) -> String {
        var text = question
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "?."))
        let lowered = text.lowercased()
        for stem in questionStems where lowered.hasPrefix(stem + " ") {
            text = String(text.dropFirst(stem.count)).trimmingCharacters(in: .whitespaces)
            break
        }
        return text
    }

    private func computeTodaySession(from sets: [StudySet], now: Date, calendar: Calendar) {
        let due = sets
            .flatMap(\.cards)
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
            set.cards
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

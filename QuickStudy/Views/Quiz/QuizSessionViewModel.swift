//
//  QuizSessionViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

@MainActor
@Observable
final class QuizSessionViewModel {
    enum Phase: Equatable {
        case answering
        case revealed(correct: Bool)
        case finished
    }

    enum QuestionState {
        case correct
        case wrong
        case current
        case upcoming
    }

    struct Reinforcement: Identifiable {
        let id: UUID
        let question: String
        let setTitle: String
        let missed: Int
    }

    struct Summary {
        let cardCount: Int
        let correctCount: Int
        let accuracy: Double
        let elapsedLabel: String
        let streak: Int
        let cardsVsYesterday: Int?
        let reinforcement: [Reinforcement]
    }

    private(set) var questions: [QuizQuestion] = []
    private(set) var index = 0
    private(set) var session = StudySession()
    private(set) var phase: Phase = .answering
    private(set) var summary: Summary?

    var selectedChoice: Int?
    var showsHint = false

    var current: QuizQuestion? {
        questions.indices.contains(index) ? questions[index] : nil
    }

    var positionLabel: String { "Session · \(index + 1) of \(questions.count)" }

    func elapsedLabel(now: Date = Date()) -> String {
        let total = Int(now.timeIntervalSince(session.startedAt))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    var states: [QuestionState] {
        questions.indices.map { position in
            if let result = session.results.first(where: { $0.cardID == questions[position].cardID }) {
                return result.correct ? .correct : .wrong
            }
            return position == index ? .current : .upcoming
        }
    }

    func start(with questions: [QuizQuestion]) {
        self.questions = questions
        index = 0
        session = StudySession()
        summary = nil
        phase = questions.isEmpty ? .finished : .answering
        reset()
    }

    func submit(study: StudyViewModel) {
        guard let question = current, let selected = selectedChoice else { return }
        let correct = selected == question.correctIndex

        study.recordAnswer(for: question.cardID, correct: correct)
        session.results.append(
            StudySession.Result(
                cardID: question.cardID,
                setID: question.setID,
                correct: correct,
                answeredAt: Date(),
                mode: .multipleChoice,
                boxBefore: question.boxBefore,
                boxAfter: study.box(for: question.cardID) ?? question.boxBefore
            )
        )
        phase = .revealed(correct: correct)
    }

    func advance(study: StudyViewModel, sessions: SessionStore) {
        if index + 1 < questions.count {
            index += 1
            reset()
            phase = .answering
        } else {
            session.endedAt = Date()
            sessions.record(session)
            study.flushPendingChanges()
            summary = makeSummary(sessions: sessions)
            phase = .finished
        }
    }

    /// A misread question shouldn't cost the user their scheduling progress.
    func undo(study: StudyViewModel) {
        guard let question = current,
              let position = session.results.lastIndex(where: { $0.cardID == question.cardID }) else { return }
        let result = session.results.remove(at: position)
        study.restoreBox(result.boxBefore, missCountDelta: result.correct ? 0 : -1, for: result.cardID)
        reset()
        phase = .answering
    }

    private func makeSummary(sessions: SessionStore, calendar: Calendar = .current) -> Summary {
        let streak = StreakCalculator.summary(
            studiedDays: sessions.studiedDays(calendar: calendar),
            frozenDays: StreakStore.frozenDays
        ).current

        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())
        let yesterdayCards = yesterday.map { sessions.cardsStudied(on: $0, calendar: calendar) } ?? 0

        let missCounts = session.results
            .filter { !$0.correct }
            .reduce(into: [UUID: Int]()) { $0[$1.cardID, default: 0] += 1 }

        let reinforcement = questions
            .compactMap { question -> Reinforcement? in
                guard let missed = missCounts[question.cardID] else { return nil }
                return Reinforcement(
                    id: question.cardID,
                    question: question.prompt,
                    setTitle: question.setTitle,
                    missed: missed
                )
            }
            .sorted { $0.missed > $1.missed }

        return Summary(
            cardCount: session.cardCount,
            correctCount: session.correctCount,
            accuracy: session.accuracy,
            elapsedLabel: session.elapsedLabel,
            streak: streak,
            cardsVsYesterday: yesterdayCards > 0 ? session.cardCount - yesterdayCards : nil,
            reinforcement: reinforcement
        )
    }

    private func reset() {
        selectedChoice = nil
        showsHint = false
    }
}

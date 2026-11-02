//
//  StudyFixesTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

/// The test host is the app, so the real stores below write to the same Documents and
/// UserDefaults as the library on that simulator. Each test puts back what it touched.
@MainActor
@Suite(.serialized)
final class StudyFixesTests {
    private let calendar = Calendar.current
    private let persisted = PersistedState.capture()

    deinit {
        persisted.restore()
    }

    private func makeStudy() throws -> StudyViewModel {
        let defaults = try #require(UserDefaults(suiteName: "StudyFixesTests"))
        let analytics = AnalyticsRecorder(defaults: defaults)
        return StudyViewModel(
            aiSettings: AISettings(),
            store: StoreController(analytics: analytics),
            analytics: analytics
        )
    }

    private func day(_ offset: Int) throws -> Date {
        try #require(calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())))
    }

    private func makeSet(_ cards: [StudyCard]) -> StudySet {
        StudySet(
            title: "Cells",
            document: StudyDocument(title: "Cells", lines: ["Mitochondria make ATP."]),
            cards: cards,
            sourceType: .paste
        )
    }

    @Test func restoreSchedulingPutsBackTheDueDateAndLastReview() throws {
        let study = try makeStudy()
        let card = StudyCard(
            question: "What makes ATP?",
            answer: "Mitochondria",
            missCount: 1,
            box: 2,
            dueDate: try day(0),
            lastReviewedAt: try day(-3)
        )
        study.savedSets = [makeSet([card])]

        let snapshot = try #require(study.card(for: card.id))
        study.recordAnswer(for: card.id, correct: false)
        study.restoreScheduling(from: snapshot)

        let restored = try #require(study.card(for: card.id))
        #expect(restored.box == 2)
        #expect(restored.missCount == 1)
        #expect(restored.dueDate == snapshot.dueDate)
        #expect(restored.lastReviewedAt == snapshot.lastReviewedAt)
    }

    @Test func dueCardsExcludesCardsDueTomorrow() throws {
        let study = try makeStudy()
        let dueToday = StudyCard(question: "Q1", answer: "A1", dueDate: try day(0))
        let neverScheduled = StudyCard(question: "Q2", answer: "A2")
        let dueTomorrow = StudyCard(question: "Q3", answer: "A3", dueDate: try day(1))
        study.savedSets = [makeSet([dueToday, neverScheduled, dueTomorrow])]

        let ids = Set(study.dueCards().map(\.id))

        #expect(ids == [dueToday.id, neverScheduled.id])
    }

    @Test func spellCheckLeavesTypedAndPDFTextUntouched() throws {
        let study = try makeStudy()
        let text = "The cristae fold the inner membrane.\nATP synthase sits on the cristae."

        let corrected = study.spellCorrect(ExtractedDocument.Page(text: text, candidates: []))

        #expect(corrected == text)
    }

    @Test func spellCheckKeepsAnOCRWordVisionNeverOffered() throws {
        let study = try makeStudy()
        let line = "The cristae fold the inner membrane."

        let corrected = study.spellCorrect(ExtractedDocument.Page(text: line, candidates: [[line]]))

        #expect(corrected == line)
    }

    @Test func deleteAllStudyDataClearsEverythingAndStopsTheSampleReseeding() throws {
        let study = try makeStudy()
        let drafts = DraftStore()
        let sessions = SessionStore()

        study.demoModeEnabled = true
        study.savedSets.append(makeSet([StudyCard(question: "Q", answer: "A")]))
        drafts.set(DraftSet(
            title: "Draft",
            document: StudyDocument(title: "Draft", lines: ["Line"]),
            cards: [StudyCard(question: "Q", answer: "A")],
            sourceType: .paste
        ))
        sessions.record(StudySession(endedAt: Date()))
        StreakStore.setFrozenDays([try day(-1)])

        study.deleteAllStudyData(drafts: drafts, sessions: sessions)

        #expect(study.savedSets.isEmpty)
        #expect(study.flashcards.isEmpty)
        #expect(study.activeSetID == nil)
        #expect(drafts.pending == nil)
        #expect(sessions.sessions.isEmpty)
        #expect(StreakStore.frozenDays.isEmpty)
        #expect(study.demoModeEnabled == false)
        #expect(UserDefaults.standard.bool(forKey: "demoModeEnabled") == false)

        let relaunched = try makeStudy()
        #expect(relaunched.savedSets.isEmpty)
    }

    @Test func deletingTheSampleSetTurnsSampleModeOff() throws {
        let study = try makeStudy()
        study.demoModeEnabled = true
        let sample = try #require(study.savedSets.first { $0.isDemo })

        study.deleteSet(sample)

        #expect(study.demoModeEnabled == false)
        #expect(!study.savedSets.contains { $0.isDemo })
    }

    @Test func singlePageSourcesLabelTheirPage() throws {
        let document = StudyDocument(
            title: "Cells.pdf",
            lines: ["Mitochondria make ATP.", "", "Ribosomes build proteins."],
            pageBreaks: [0]
        )

        let source = try #require(CardSourceLocator.locate(excerpt: "Ribosomes build proteins", in: document))

        #expect(source.shortLabel == "p.1 ¶2")
    }

    @Test func documentSavedWithoutPageBreaksStillDecodesAsPasted() throws {
        let json = """
        {
            "title": "Pasted Notes",
            "lines": ["Mitochondria make ATP."]
        }
        """.data(using: .utf8)!

        let document = try JSONDecoder().decode(StudyDocument.self, from: json)
        let source = try #require(CardSourceLocator.locate(excerpt: "Mitochondria make ATP", in: document))

        #expect(document.pageBreaks == nil)
        #expect(source.shortLabel == "¶1")
    }
}

private struct PersistedState {
    private static let fileNames = ["SavedSets.json", "PendingDraft.json", "Sessions.json"]
    private static let defaultsKeys = ["demoModeEnabled", "qs_spellCheckEnabled", "qs_frozenDays"]

    let files: [URL: Data?]
    let defaults: [String: Any?]

    static func capture() -> PersistedState {
        let urls = fileNames.map { JSONFile(named: $0).url }
        return PersistedState(
            files: Dictionary(uniqueKeysWithValues: urls.map { ($0, FileManager.default.contents(atPath: $0.path)) }),
            defaults: Dictionary(uniqueKeysWithValues: defaultsKeys.map { ($0, UserDefaults.standard.object(forKey: $0)) })
        )
    }

    func restore() {
        for (url, data) in files {
            if let data {
                FileManager.default.createFile(atPath: url.path, contents: data)
            } else {
                // Absent before the test; a missing file now is the state being restored.
                try? FileManager.default.removeItem(at: url)
            }
        }
        for (key, value) in defaults {
            UserDefaults.standard.set(value, forKey: key)
        }
    }
}

//
//  StudyModelCodingTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
@testable import QuickStudy

struct StudyModelCodingTests {
    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    @Test func studyCardRoundTripsThroughJSON() throws {
        let source = CardSource(
            documentTitle: "HIG-notes.pdf",
            page: 3,
            paragraph: 2,
            lineRange: 10...14,
            excerpt: "Liquid Glass refracts the content behind it."
        )
        let card = StudyCard(
            question: "What does Liquid Glass do?",
            answer: "Refracts the content behind it.",
            missCount: 2,
            box: 3,
            dueDate: Date(timeIntervalSince1970: 1_780_000_000),
            lastReviewedAt: Date(timeIntervalSince1970: 1_779_000_000),
            source: source,
            explanation: "Because it is a material, not a fill.",
            distractors: ["Tints the content", "Blurs the content", "Hides the content"]
        )

        let data = try makeEncoder().encode(card)
        let decoded = try makeDecoder().decode(StudyCard.self, from: data)

        #expect(decoded == card)
    }

    @Test func draftSetRoundTripsThroughJSON() throws {
        let document = StudyDocument(
            title: "HIG-notes.pdf",
            lines: ["Liquid Glass is a material.", "", "It refracts content behind it."],
            pageBreaks: [0]
        )
        let card = StudyCard(question: "Q1", answer: "A1")
        let draft = DraftSet(
            title: "HIG Notes",
            document: document,
            cards: [card],
            sourceType: .pdf,
            createdAt: Date(timeIntervalSince1970: 1_780_000_000)
        )

        let data = try makeEncoder().encode(draft)
        let decoded = try makeDecoder().decode(DraftSet.self, from: data)

        #expect(decoded.id == draft.id)
        #expect(decoded.title == draft.title)
        #expect(decoded.document == draft.document)
        #expect(decoded.cards == draft.cards)
        #expect(decoded.sourceType == draft.sourceType)
        #expect(decoded.createdAt == draft.createdAt)
    }

    @Test func studyCardDecodesWithDefaultsWhenOptionalKeysAreMissing() throws {
        let json = """
        {
            "id": "\(UUID().uuidString)",
            "question": "What is on-device generation?",
            "answer": "Generation that never leaves the device.",
            "missCount": 0
        }
        """.data(using: .utf8)!

        let decoded = try makeDecoder().decode(StudyCard.self, from: json)

        #expect(decoded.box == ReviewSchedule.newBox)
        #expect(decoded.dueDate == nil)
        #expect(decoded.lastReviewedAt == nil)
        #expect(decoded.source == nil)
        #expect(decoded.explanation == nil)
        #expect(decoded.distractors == [])
    }
}

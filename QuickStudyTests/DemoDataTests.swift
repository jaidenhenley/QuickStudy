//
//  DemoDataTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct DemoDataTests {
    /// The quiz runs every card's distractors through the refiner and backfills from other
    /// cards' answers when any are dropped, which shows a correct answer as a wrong option.
    @Test func everyDistractorSurvivesTheRefiner() {
        for card in DemoData.set.cards {
            let kept = DistractorRefiner.refine(card.distractors, answer: card.answer, source: nil)
            #expect(kept == card.distractors, "\(card.question)")
        }
    }

    @Test func everySourcePointsAtItsOwnPage() {
        let spec = DemoData.set
        for card in spec.cards {
            let source = spec.source(for: card)
            let line = try! #require(source.lineRange?.lowerBound)
            #expect(spec.pages[card.page - 1].contains(spec.lines[line]), "\(card.question)")
            #expect(source.excerpt == spec.lines[line])
        }
    }

    @Test func pageBreaksStartEachPage() {
        #expect(DemoData.set.pageBreaks == [0, DemoData.set.pages[0].count])
    }
}

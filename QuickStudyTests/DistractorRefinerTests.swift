//
//  DistractorRefinerTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct DistractorRefinerTests {
    @Test func changedNumberIsNotAParaphrase() {
        let kept = DistractorRefiner.refine(
            ["roughly 3 percent", "roughly 50 percent", "about 97 percent"],
            answer: "roughly 97 percent",
            source: nil
        )
        #expect(kept == ["roughly 3 percent", "roughly 50 percent"])
    }

    @Test func sentenceIsRejectedWhenAnswerIsAPhrase() {
        let kept = DistractorRefiner.refine(
            ["The Third Estate bore the fiscal burden.", "the bourgeoisie and peasants"],
            answer: "the nobility and clergy",
            source: nil
        )
        #expect(kept == ["the bourgeoisie and peasants"])
    }

    @Test func backfillSkipsAnswersOfADifferentKind() {
        let kept = DistractorRefiner.backfill(
            ["a severe fiscal crisis", "the nobility and clergy", "about 3 percent"],
            answer: "roughly 97 percent",
            existing: [],
            needed: 3
        )
        #expect(kept == ["about 3 percent"])
    }
}

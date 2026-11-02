//
//  ContentAnalysisTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct ContentAnalysisTests {
    @Test func theEstimateFollowsWordCountAndReadsInTheSingular() {
        let one = ContentAnalysis.immediate(for: "The heart has four chambers.")
        #expect(one.estimatedCards == 1)
        #expect(one.estimatedCardsLabel == "~1 card")

        let tenWords = "Cells divide by mitosis, which has four distinct ordered stages. "
        let notes = String(repeating: tenWords, count: 40)
        let sixteen = ContentAnalysis.immediate(for: notes)
        #expect(sixteen.wordCount == 400)
        #expect(sixteen.estimatedCards == 16)
        #expect(sixteen.estimatedCardsLabel == "~16 cards")
    }
}

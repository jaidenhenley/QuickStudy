//
//  ContentAnalysisTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct ContentAnalysisTests {
    @Test func theEstimateFollowsSentencesAndReadsInTheSingular() {
        let one = ContentAnalysis.immediate(for: "The heart has four chambers.")
        #expect(one.estimatedCards == 1)
        #expect(one.estimatedCardsLabel == "~1 card")

        let four = ContentAnalysis.immediate(for: "Cells divide by mitosis. Mitosis has four stages. Prophase comes first. Telophase comes last.")
        #expect(four.estimatedCards == 4)
        #expect(four.estimatedCardsLabel == "~4 cards")
    }
}

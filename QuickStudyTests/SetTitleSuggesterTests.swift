//
//  SetTitleSuggesterTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct SetTitleSuggesterTests {
    @Test func shortFirstLineIsUsedAsAHeading() {
        #expect(SetTitleSuggester.title(from: ["Key terms in cellular biology.", "Osmosis is…"]) == "Key terms in cellular biology")
    }

    @Test func longOpeningSentenceYieldsItsSubject() {
        let lines = ["Photosynthesis is the process by which plants, algae, and some bacteria convert light energy into chemical energy."]
        #expect(SetTitleSuggester.title(from: lines) == "Photosynthesis")
    }

    @Test func longSentenceWithoutADefiningVerbFallsBackToItsFirstWords() {
        let lines = ["The human circulatory system transports blood, oxygen, nutrients, hormones, and waste products throughout the body."]
        #expect(SetTitleSuggester.title(from: lines) == "The human circulatory system")
    }

    @Test func leadingBlankLinesAreSkipped() {
        #expect(SetTitleSuggester.title(from: ["", "   ", "Lecture 4 notes"]) == "Lecture 4 notes")
    }

    @Test func nothingUsableReturnsNil() {
        #expect(SetTitleSuggester.title(from: []) == nil)
        #expect(SetTitleSuggester.title(from: ["??"]) == nil)
    }
}

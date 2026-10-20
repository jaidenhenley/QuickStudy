//
//  CardSourceLocatorTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

struct CardSourceLocatorTests {
    private let document = StudyDocument(
        title: "Cells",
        lines: [
            "Cells are the basic unit of life.",
            "The nucleus holds the cell's DNA and controls its activity.",
            "Ribosomes build proteins from amino acids.",
            "Mitochondria release energy from glucose during respiration.",
            "Chloroplasts capture light energy in plant cells."
        ],
        pageBreaks: [0, 3]
    )

    @Test func aSingleLineExcerptIsNotPulledBackOntoAShorterLineBeforeIt() {
        let source = CardSourceLocator.locate(excerpt: "The nucleus holds the cell's DNA and controls its activity.", in: document)
        #expect(source?.lineRange == 1...1)
        #expect(source?.excerpt == "The nucleus holds the cell's DNA and controls its activity.")
    }

    @Test func anExcerptSpanningTwoLinesCoversExactlyThoseLines() {
        let source = CardSourceLocator.locate(excerpt: "controls its activity. Ribosomes build proteins", in: document)
        #expect(source?.lineRange == 1...2)
    }

    @Test func theFirstLineOfASecondPageReportsThatPage() {
        let source = CardSourceLocator.locate(excerpt: "Mitochondria release energy from glucose during respiration.", in: document)
        #expect(source?.lineRange == 3...3)
        #expect(source?.page == 2)
    }

    @Test func anUnmatchedExcerptKeepsItsTextWithoutAPosition() {
        let source = CardSourceLocator.locate(excerpt: "Something the document never says.", in: document)
        #expect(source?.lineRange == nil)
        #expect(source?.page == nil)
        #expect(source?.paragraph == nil)
        #expect(source?.excerpt == "Something the document never says.")
    }
}

//
//  ImportFlowTests.swift
//  QuickStudyTests
//

import PDFKit
import Testing
import UIKit
@testable import QuickStudy

@MainActor
struct ImportFlowTests {
    private func draft(lines: [String], pageBreaks: [Int]?) -> DraftSet {
        DraftSet(
            title: "Cell Biology",
            document: StudyDocument(title: "Cell Biology", lines: lines, pageBreaks: pageBreaks),
            cards: [],
            sourceType: .pdf
        )
    }

    private func pdf(pages: Int) throws -> PDFDocument {
        let document = PDFDocument()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { _ in }
        for index in 0..<pages {
            let page = try #require(PDFPage(image: image))
            document.insert(page, at: index)
        }
        return document
    }

    @Test func chosenPagesCountOnlyThePagesThatHoldText() {
        let lines = ["Page four.", "Page five.", "Page six."]
        let chosen = draft(lines: lines, pageBreaks: [0, 0, 0, 0, 1, 2])

        #expect(chosen.contentPages == [4, 5, 6])
        #expect(chosen.pageCount == 3)
        #expect(chosen.pageRangeLabel == "pages 4 to 6")
    }

    @Test func scatteredPagesAreCountedNotRanged() {
        let lines = ["Page two.", "Page five."]
        let chosen = draft(lines: lines, pageBreaks: [0, 0, 1, 1, 1])

        #expect(chosen.contentPages == [2, 5])
        #expect(chosen.pageRangeLabel == "2 pages")
    }

    @Test func pastedTextHasNoPageLabel() {
        let pasted = draft(lines: ["Some notes."], pageBreaks: nil)

        #expect(pasted.pageCount == 1)
        #expect(pasted.pageRangeLabel == nil)
    }

    @Test func choosePagesPreselectsTheFirstTenAndCapsTheSelection() throws {
        let viewModel = ChoosePagesViewModel(fileName: "Cell Biology.pdf", document: try pdf(pages: 12))

        #expect(viewModel.sortedSelection == Array(0..<10))
        #expect(viewModel.summary == "Pages 1 to 10 selected")
        #expect(viewModel.buttonTitle == "Draft 10 Pages")

        viewModel.toggle(11)
        #expect(!viewModel.isSelected(11))

        viewModel.toggle(0)
        viewModel.toggle(11)
        #expect(viewModel.isSelected(11))
        #expect(viewModel.summary == "10 pages selected")
    }
}

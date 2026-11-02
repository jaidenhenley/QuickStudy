//
//  ImportStageTests.swift
//  QuickStudyTests
//

import Foundation
import Testing
import UIKit
@testable import QuickStudy

@MainActor
struct ImportStageTests {
    private let helper = DocumentImportHelper(isHandwritingMode: false, isUltraHandwritingMode: false)

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).pdf")
    }

    private func makeTextPDF(pages: [String]) throws -> URL {
        let url = temporaryURL()
        let bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        try UIGraphicsPDFRenderer(bounds: bounds).writePDF(to: url) { context in
            for text in pages {
                context.beginPage()
                (text as NSString).draw(
                    in: bounds.insetBy(dx: 48, dy: 48),
                    withAttributes: [.font: UIFont.systemFont(ofSize: 18)]
                )
            }
        }
        return url
    }

    @Test func aCorruptPDFThrowsInsteadOfReadingAsEmpty() async throws {
        let url = temporaryURL()
        try Data("this is not a pdf".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        await #expect(throws: DocumentImportError.self) {
            _ = try await helper.extractText(from: url)
        }
    }

    @Test func aTextPDFKeepsItsPagesAndReportsProgressOnce() async throws {
        let url = try makeTextPDF(pages: [
            "Mitochondria release energy from glucose during respiration.",
            "Ribosomes build proteins from amino acids in the cytoplasm."
        ])
        defer { try? FileManager.default.removeItem(at: url) }

        var reports: [[Int]] = []
        let extracted = try await helper.extractText(from: url) { page, total in
            reports.append([page, total])
        }

        #expect(extracted.pages.count == 2)
        #expect(extracted.pages[0].text.contains("Mitochondria"))
        #expect(extracted.pages[1].text.contains("Ribosomes"))
        #expect(reports == [[2, 2]])
    }
}

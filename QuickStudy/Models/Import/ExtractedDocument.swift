//
//  ExtractedDocument.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

/// Import output kept page by page. Page boundaries have to survive spell-check, OCR
/// repair and normalisation — each of which changes line counts — so every page runs
/// the pipeline independently rather than being flattened up front.
struct ExtractedDocument {
    struct Page {
        let text: String
        let candidates: [[String]]
    }

    let pages: [Page]

    var isEmpty: Bool {
        pages.allSatisfy { $0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var joinedText: String {
        pages.map(\.text).joined(separator: "\n")
    }
}

//
//  CardSource.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation

struct CardSource: Codable, Equatable, Hashable {
    var documentTitle: String
    var page: Int?
    var paragraph: Int?
    var lineRange: ClosedRange<Int>?
    var excerpt: String

    /// "p.3 ¶2" — the pill on every draft and quiz question.
    var shortLabel: String {
        var parts: [String] = []
        if let page { parts.append(String(localized: "p.\(page)", comment: "Abbreviated page number on the source pill, as in p.3 ¶2.")) }
        if let paragraph { parts.append("¶\(paragraph)") }
        return parts.isEmpty ? documentTitle : parts.joined(separator: " ")
    }

    /// "From HIG-notes.pdf, page 2" — the attribution under a wrong answer.
    var longLabel: String {
        guard let page else { return String(localized: "From \(documentTitle)") }
        return String(localized: "From \(documentTitle), page \(page)")
    }
}

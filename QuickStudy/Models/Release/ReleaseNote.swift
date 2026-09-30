//
//  ReleaseNote.swift
//  QuickStudy
//

import Foundation

struct ReleaseNote: Identifiable, Equatable {
    struct Feature: Identifiable, Equatable {
        let symbol: String
        let title: String
        let detail: String

        var id: String { title }
    }

    /// Bumped only for releases worth announcing, so a bug-fix version never re-shows the sheet.
    let release: Int
    let version: String
    let headline: String
    let features: [Feature]
    let proFeature: Feature?
    let cloudNotice: String?

    var id: Int { release }
}

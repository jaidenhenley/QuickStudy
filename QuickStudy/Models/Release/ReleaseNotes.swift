//
//  ReleaseNotes.swift
//  QuickStudy
//

import Foundation

enum ReleaseNotes {
    static let current = ReleaseNote(
        release: 2,
        version: "2.0",
        headline: String(localized: "QuickStudy has been rebuilt around studying every day."),
        features: [
            .init(
                symbol: "house",
                title: String(localized: "One session a day"),
                detail: String(localized: "Today shows only the cards that are due, plus your weakest card.")
            ),
            .init(
                symbol: "rectangle.stack",
                title: String(localized: "Drafts are kept"),
                detail: String(localized: "Swipe to remove. No more approving every card.")
            ),
            .init(
                symbol: "doc.text.magnifyingglass",
                title: String(localized: "Linked to your notes"),
                detail: String(localized: "Each card links back to the page and passage it came from.")
            ),
            .init(
                symbol: "lightbulb",
                title: String(localized: "Know why"),
                detail: String(localized: "Every answer explains why it's right. Missed cards come back tomorrow.")
            ),
            .init(
                symbol: "flame.fill",
                title: String(localized: "Streaks and Streak Freezes"),
                detail: String(localized: "Session results, streaks, and a freeze for every full study week.")
            )
        ],
        proFeature: .init(
            symbol: "sparkles",
            title: "QuickStudy Pro",
            detail: String(localized: "\(ProProduct.hostedMonthlyLimit) cloud generations a month on any iPhone.")
        ),
        cloudNotice: String(localized: "Your next set can be drafted in the cloud, with your permission.")
    )
}

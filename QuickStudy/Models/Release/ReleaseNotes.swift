//
//  ReleaseNotes.swift
//  QuickStudy
//

import Foundation

enum ReleaseNotes {
    static let current = ReleaseNote(
        release: 2,
        version: "2.0",
        headline: "QuickStudy has been rebuilt around studying every day.",
        features: [
            .init(
                symbol: "house",
                title: "One session a day",
                detail: "Today shows only the cards that are due, plus your weakest card."
            ),
            .init(
                symbol: "rectangle.stack",
                title: "Drafts are kept",
                detail: "Swipe to remove. No more approving every card."
            ),
            .init(
                symbol: "doc.text.magnifyingglass",
                title: "Linked to your notes",
                detail: "Each card links back to the page and passage it came from."
            ),
            .init(
                symbol: "lightbulb",
                title: "Know why",
                detail: "Every answer explains why it's right. Missed cards come back tomorrow."
            ),
            .init(
                symbol: "flame.fill",
                title: "Streaks and Streak Freezes",
                detail: "Session results, streaks, and a freeze for every full study week."
            )
        ],
        proFeature: .init(
            symbol: "sparkles",
            title: "QuickStudy Pro",
            detail: "\(ProProduct.hostedMonthlyLimit) cloud generations a month for better cards on any iPhone."
        ),
        cloudNotice: "Your next set can be drafted in the cloud, with your permission."
    )
}

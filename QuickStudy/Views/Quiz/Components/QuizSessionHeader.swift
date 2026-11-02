//
//  QuizSessionHeader.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/22/26.
//

import SwiftUI

struct QuizSessionHeader: View {
    let positionLabel: String
    let positionAccessibilityLabel: String
    let elapsedLabel: (Date) -> String
    let states: [QuizSessionViewModel.QuestionState]
    let currentIndex: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // At accessibility sizes the full "Session · 3 of 17" truncates, so the visible text
        // drops the prefix while the spoken label keeps it.
        let visibleLabel = dynamicTypeSize.isAccessibilitySize
            ? "\(currentIndex + 1) of \(states.count)"
            : positionLabel

        VStack(alignment: .leading, spacing: Spacing.base) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    Text(visibleLabel)
                        .font(.headline)
                        .accessibilityLabel(positionAccessibilityLabel)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    ElapsedTimerText(label: elapsedLabel)
                }
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(visibleLabel)
                        .font(.headline)
                        .accessibilityLabel(positionAccessibilityLabel)
                        .accessibilityAddTraits(.isHeader)
                    ElapsedTimerText(label: elapsedLabel)
                }
            }

            SessionProgressBar(states: states, currentIndex: currentIndex)
        }
    }
}

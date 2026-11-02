//
//  SessionProgressBar.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionProgressBar: View {
    let states: [QuizSessionViewModel.QuestionState]

    @ScaledMetric(relativeTo: .caption) private var segmentHeight = 6

    var body: some View {
        HStack(spacing: 3) {
            ForEach(states.indices, id: \.self) { index in
                Capsule()
                    .fill(color(for: states[index]))
                    .frame(height: segmentHeight)
                    .overlay {
                        switch states[index] {
                        case .correct:
                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, segmentHeight * 0.2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.onPrimary)
                                .appTransition(.scale.combined(with: .opacity))
                        case .wrong:
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .padding(.vertical, segmentHeight * 0.2)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.onPrimary)
                                .appTransition(.scale.combined(with: .opacity))
                        case .current, .upcoming:
                            EmptyView()
                        }
                    }
            }
        }
        .appAnimation(Motion.snappy, value: states)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Session progress")
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: String {
        let position = (states.firstIndex(of: .current) ?? states.count - 1) + 1
        let correct = states.filter { $0 == .correct }.count
        let wrong = states.filter { $0 == .wrong }.count
        return "Question \(max(position, 1)) of \(states.count), \(correct) correct, \(wrong) missed"
    }

    private func color(for state: QuizSessionViewModel.QuestionState) -> Color {
        switch state {
        case .correct: return Theme.success
        case .wrong: return Theme.danger
        case .current: return Color.appPrimary
        case .upcoming: return Theme.track
        }
    }
}

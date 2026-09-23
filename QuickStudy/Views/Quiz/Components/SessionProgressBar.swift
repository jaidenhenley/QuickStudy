//
//  SessionProgressBar.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionProgressBar: View {
    let states: [QuizSessionViewModel.QuestionState]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(states.indices, id: \.self) { index in
                Capsule()
                    .fill(color(for: states[index]))
                    .frame(height: 4)
                    .overlay {
                        switch states[index] {
                        case .correct:
                            Image(systemName: "checkmark")
                                .font(.system(size: 5, weight: .bold))
                                .foregroundStyle(.white)
                        case .wrong:
                            Image(systemName: "xmark")
                                .font(.system(size: 5, weight: .bold))
                                .foregroundStyle(.white)
                        case .current, .upcoming:
                            EmptyView()
                        }
                    }
            }
        }
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
        case .upcoming: return Color.secondary.opacity(0.25)
        }
    }
}

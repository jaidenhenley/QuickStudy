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
            }
        }
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

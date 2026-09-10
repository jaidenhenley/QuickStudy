//
//  QuizSessionView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Combine
import SwiftUI
import UIKit

struct QuizSessionView: View {
    let cards: [StudyCard]

    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    @State private var quizSessionViewModel = QuizSessionViewModel()
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let letters = ["A", "B", "C", "D", "E"]

    var body: some View {
        Group {
            if let summary = quizSessionViewModel.summary {
                SessionCompleteView(
                    summary: summary,
                    onAgain: start,
                    onDone: { dismiss() }
                )
            } else if let question = quizSessionViewModel.current {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    HStack {
                        Text(quizSessionViewModel.positionLabel)
                            .font(.headline)
                        Spacer()
                        Text(quizSessionViewModel.elapsedLabel(now: now))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    SessionProgressBar(states: quizSessionViewModel.states)

                    // The counter, timer, progress bar and CTA stay pinned; only the
                    // question body scrolls, so a long prompt or four long choices no
                    // longer clip and Submit is always reachable.
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.base) {
                            HStack {
                                Text(question.setTitle.uppercased())
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .tracking(1)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                if question.source != nil {
                                    Button {
                                        withAnimation { quizSessionViewModel.showsHint.toggle() }
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "link")
                                            Text("Why?")
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    }
                                }
                            }

                            if quizSessionViewModel.showsHint, let excerpt = question.source?.excerpt {
                                Text(excerpt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(Spacing.md)
                                    .appGlassCard(cornerRadius: AppRadius.md)
                            }

                            if case let .revealed(correct) = quizSessionViewModel.phase {
                                if !correct, let selected = quizSessionViewModel.selectedChoice {
                                    ResultCard(
                                        label: "YOUR ANSWER",
                                        text: question.choices[selected],
                                        tint: Theme.danger,
                                        symbol: "x.circle.fill"
                                    )
                                }

                                ResultCard(
                                    label: "CORRECT",
                                    text: question.choices[question.correctIndex],
                                    tint: Theme.success,
                                    symbol: "checkmark.circle.fill"
                                )

                                WhySourceCard(explanation: question.explanation, source: question.source)

                                if !correct {
                                    HStack {
                                        Text("We'll surface this one again tomorrow.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Button("Undo") { quizSessionViewModel.undo(study: studyViewModel) }
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                }
                            } else {
                                Text("QUESTION")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .tracking(1)
                                    .foregroundStyle(.secondary)

                                Text(question.prompt)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Spacing.base)
                                    .appGlassCard(cornerRadius: AppRadius.lg)

                                ForEach(question.choices.indices, id: \.self) { index in
                                    QuizChoiceRow(
                                        letter: letters[min(index, letters.count - 1)],
                                        text: question.choices[index],
                                        isSelected: quizSessionViewModel.selectedChoice == index
                                    ) {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        quizSessionViewModel.selectedChoice = index
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Spacing.sm)
                        .id(question.cardID)
                    }
                    .scrollBounceBehavior(.basedOnSize)

                    if case .revealed = quizSessionViewModel.phase {
                        Button {
                            quizSessionViewModel.advance(study: studyViewModel, sessions: sessionStore)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text("Next question")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                        }
                        .appProminentButtonStyle(tint: Theme.primary)
                    } else {
                        Button {
                            quizSessionViewModel.submit(study: studyViewModel)
                            UINotificationFeedbackGenerator().notificationOccurred(
                                quizSessionViewModel.phase == .revealed(correct: true) ? .success : .error
                            )
                        } label: {
                            Text("Submit")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .appProminentButtonStyle(tint: Theme.primary)
                        .disabled(quizSessionViewModel.selectedChoice == nil)
                    }
                }
                .padding(Spacing.lg)
            } else {
                Text("No cards due right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .background(BackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: quizSessionViewModel.phase)
        .onReceive(ticker) { tick in
            if quizSessionViewModel.phase != .finished { now = tick }
        }
        .onAppear { if quizSessionViewModel.questions.isEmpty { start() } }
    }

    private func start() {
        quizSessionViewModel.start(with: studyViewModel.sessionQuestions(for: cards))
    }
}

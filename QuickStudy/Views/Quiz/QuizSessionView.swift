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

    @State private var engine = QuizSessionViewModel()
    @State private var now = Date()

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let letters = ["A", "B", "C", "D", "E"]

    var body: some View {
        Group {
            if engine.phase == .finished {
                SessionCompleteView(
                    summary: engine.summary(sessions: sessionStore),
                    onAgain: start,
                    onDone: { dismiss() }
                )
            } else if let question = engine.current {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    HStack {
                        Text(engine.positionLabel)
                            .font(.headline)
                        Spacer()
                        Text(engine.elapsedLabel(now: now))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    SessionProgressBar(states: engine.states)

                    HStack {
                        Text(question.setTitle.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tracking(1)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if question.source != nil {
                            Button {
                                withAnimation { engine.showsHint.toggle() }
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

                    if engine.showsHint, let excerpt = question.source?.excerpt {
                        Text(excerpt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(Spacing.md)
                            .appGlassCard(cornerRadius: AppRadius.md)
                    }

                    if case let .revealed(correct) = engine.phase {
                        if !correct, let selected = engine.selectedChoice {
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
                                Button("Undo") { engine.undo(study: studyViewModel) }
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
                                isSelected: engine.selectedChoice == index
                            ) {
                                UISelectionFeedbackGenerator().selectionChanged()
                                engine.selectedChoice = index
                            }
                        }
                    }

                    Spacer(minLength: 0)

                    if case .revealed = engine.phase {
                        Button {
                            engine.advance(study: studyViewModel, sessions: sessionStore)
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
                            engine.submit(study: studyViewModel)
                            UINotificationFeedbackGenerator().notificationOccurred(
                                engine.phase == .revealed(correct: true) ? .success : .error
                            )
                        } label: {
                            Text("Submit")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .appProminentButtonStyle(tint: Theme.primary)
                        .disabled(engine.selectedChoice == nil)
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
        .animation(.default, value: engine.phase)
        .onReceive(ticker) { now = $0 }
        .onAppear { if engine.questions.isEmpty { start() } }
    }

    private func start() {
        engine.start(with: studyViewModel.sessionQuestions(for: cards))
    }
}

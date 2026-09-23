//
//  QuizSessionView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Combine
import SwiftUI

struct QuizSessionView: View {
    let cards: [StudyCard]

    private enum AccessibilityFocusTarget: Hashable {
        case question
        case result
    }

    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var quizSessionViewModel = QuizSessionViewModel()
    @State private var now = Date()
    @AccessibilityFocusState private var focusTarget: AccessibilityFocusTarget?

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
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(quizSessionViewModel.positionLabel)
                                .font(.headline)
                            Spacer()
                            Text(quizSessionViewModel.elapsedLabel(now: now))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(quizSessionViewModel.positionLabel)
                                .font(.headline)
                            Text(quizSessionViewModel.elapsedLabel(now: now))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
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
                                if let source = question.source {
                                    Button {
                                        if reduceMotion {
                                            quizSessionViewModel.showsHint.toggle()
                                        } else {
                                            withAnimation { quizSessionViewModel.showsHint.toggle() }
                                        }
                                    } label: {
                                        HStack(spacing: Spacing.xs) {
                                            Image(systemName: "link")
                                                .accessibilityHidden(true)
                                            Text("Why?")
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    }
                                    .accessibilityLabel("Why this answer, source \(source.longLabel)")
                                }
                            }

                            if quizSessionViewModel.showsHint, let excerpt = question.source?.excerpt {
                                Text(excerpt)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(Spacing.md)
                                    .appGlassCard(cornerRadius: AppRadius.md)
                            }

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
                                .accessibilityFocused($focusTarget, equals: .question)

                            if case let .revealed(correct) = quizSessionViewModel.phase {
                                VStack(alignment: .leading, spacing: Spacing.base) {
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
                                }
                                .accessibilityElement(children: .contain)
                                .accessibilityFocused($focusTarget, equals: .result)
                            } else {
                                ForEach(question.choices.indices, id: \.self) { index in
                                    QuizChoiceRow(
                                        letter: letters[min(index, letters.count - 1)],
                                        text: question.choices[index],
                                        isSelected: quizSessionViewModel.selectedChoice == index
                                    ) {
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
                            focusTarget = .question
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
                            focusTarget = .result
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
                .sensoryFeedback(.selection, trigger: quizSessionViewModel.selectedChoice)
                .sensoryFeedback(trigger: quizSessionViewModel.phase) { _, newPhase in
                    switch newPhase {
                    case .revealed(let correct): return correct ? .success : .error
                    case .answering, .finished: return nil
                    }
                }
            } else {
                Text("No cards due right now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .background(BackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .animation(reduceMotion ? nil : .default, value: quizSessionViewModel.phase)
        .onReceive(ticker) { tick in
            if quizSessionViewModel.phase != .finished { now = tick }
        }
        .onAppear {
            if quizSessionViewModel.questions.isEmpty { start() }
            focusTarget = .question
        }
        .onDisappear {
            quizSessionViewModel.recordPartialSessionIfNeeded(study: studyViewModel, sessions: sessionStore)
        }
    }

    private func start() {
        quizSessionViewModel.start(with: studyViewModel.sessionQuestions(for: cards))
        focusTarget = .question
    }
}

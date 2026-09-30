//
//  QuizSessionView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

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

    @State private var quizSessionViewModel = QuizSessionViewModel()
    @AccessibilityFocusState private var focusTarget: AccessibilityFocusTarget?

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
                            ElapsedTimerText(label: quizSessionViewModel.elapsedLabel(now:))
                        }
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(quizSessionViewModel.positionLabel)
                                .font(.headline)
                            ElapsedTimerText(label: quizSessionViewModel.elapsedLabel(now:))
                        }
                    }

                    SessionProgressBar(states: quizSessionViewModel.states)

                    // The counter, timer, progress bar and CTA stay pinned; only the
                    // question body scrolls, so a long prompt or four long choices no
                    // longer clip and Submit is always reachable.
                    ScrollView {
                        // A ZStack overlaps the outgoing and incoming questions during the slide;
                        // the scroll view's implicit vertical stack would stack them instead.
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: Spacing.base) {
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
                                                quizSessionViewModel.showsHint.toggle()
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
                                            .appTransition(.opacity.combined(with: .move(edge: .top)))
                                    }
                                }
                                .appAnimation(Motion.snappy, value: quizSessionViewModel.showsHint)

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
                                                symbol: "x.circle.fill",
                                                emphasis: .shake
                                            )
                                        }

                                        ResultCard(
                                            label: "CORRECT",
                                            text: question.choices[question.correctIndex],
                                            tint: Theme.success,
                                            symbol: "checkmark.circle.fill",
                                            emphasis: correct ? .pop : nil
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
                                    .appTransition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
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
                            .appTransition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        }
                        // Pins the advance to its own curve; the screen-wide phase spring would
                        // otherwise override it, since every advance also changes phase.
                        .appAnimation(Motion.standard, value: question.cardID)
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
        .appAnimation(Motion.emphasized, value: quizSessionViewModel.phase)
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

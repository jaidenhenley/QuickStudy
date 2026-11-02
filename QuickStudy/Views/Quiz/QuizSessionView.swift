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
        case correctAnswer
    }

    @Environment(StudyViewModel.self) private var studyViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var quizSessionViewModel = QuizSessionViewModel()
    @AccessibilityFocusState private var focusTarget: AccessibilityFocusTarget?

    private let letters = ["A", "B", "C", "D", "E"]

    private var headerScrolls: Bool {
        verticalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize
    }

    // Pinned above the CTA it stays visible at rest; where space is tight it scrolls with the answer instead.
    private var pinsUndoRow: Bool { !headerScrolls }

    var body: some View {
        Group {
            if let summary = quizSessionViewModel.summary {
                SessionCompleteView(
                    summary: summary,
                    onAgain: {
                        quizSessionViewModel.startNextSession(study: studyViewModel)
                        focusTarget = .question
                    },
                    onDone: { dismiss() }
                )
            } else if let question = quizSessionViewModel.current {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    if !headerScrolls {
                        QuizSessionHeader(
                            positionLabel: quizSessionViewModel.positionLabel,
                            positionAccessibilityLabel: quizSessionViewModel.positionAccessibilityLabel,
                            elapsedLabel: quizSessionViewModel.elapsedLabel(now:),
                            states: quizSessionViewModel.states,
                            currentIndex: quizSessionViewModel.index
                        )
                    }

                    // The header and CTA stay pinned; only the question body scrolls, so a long
                    // prompt or four long choices no longer clip and Submit is always reachable.
                    // In landscape and at accessibility sizes the header scrolls too, since pinned
                    // it would leave almost no room for the question.
                    ScrollView {
                        if headerScrolls {
                            QuizSessionHeader(
                                positionLabel: quizSessionViewModel.positionLabel,
                                positionAccessibilityLabel: quizSessionViewModel.positionAccessibilityLabel,
                                elapsedLabel: quizSessionViewModel.elapsedLabel(now:),
                                states: quizSessionViewModel.states,
                                currentIndex: quizSessionViewModel.index
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // A ZStack overlaps the outgoing and incoming questions during the slide;
                        // the scroll view's implicit vertical stack would stack them instead.
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: Spacing.base) {
                                VStack(alignment: .leading, spacing: Spacing.base) {
                                    let categoryLayout = dynamicTypeSize.isAccessibilitySize
                                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                                        : AnyLayout(HStackLayout())

                                    categoryLayout {
                                        Text(question.setTitle)
                                            .textCase(.uppercase)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .tracking(1)
                                            .foregroundStyle(.secondary)
                                        if !dynamicTypeSize.isAccessibilitySize {
                                            Spacer()
                                        }
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
                                                .frame(minWidth: 44, minHeight: 44)
                                                .contentShape(Rectangle())
                                            }
                                            .accessibilityLabel("Why this answer, source \(source.longLabel)")
                                            .accessibilityValue(quizSessionViewModel.showsHint ? "Shown" : "Hidden")
                                            .accessibilityHint("Shows the source excerpt")
                                            // Hidden rather than removed until the answer is submitted, so revealing
                                            // it never moves the question or the options.
                                            .opacity(quizSessionViewModel.isWhyAvailable ? 1 : 0)
                                            .allowsHitTesting(quizSessionViewModel.isWhyAvailable)
                                            .accessibilityHidden(!quizSessionViewModel.isWhyAvailable)
                                        }
                                    }

                                    if quizSessionViewModel.isWhyAvailable, quizSessionViewModel.showsHint, let excerpt = question.source?.excerpt {
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
                                    .accessibilityAddTraits(.isHeader)

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
                                                spokenLabel: "Your answer, incorrect",
                                                emphasis: .shake
                                            )
                                            .accessibilityFocused($focusTarget, equals: .result)
                                        }

                                        ResultCard(
                                            label: "CORRECT",
                                            text: question.choices[question.correctIndex],
                                            tint: Theme.success,
                                            symbol: "checkmark.circle.fill",
                                            spokenLabel: correct ? "Correct" : "Correct answer",
                                            emphasis: correct ? .pop : nil
                                        )
                                        .accessibilityFocused($focusTarget, equals: correct ? .result : .correctAnswer)

                                        WhySourceCard(explanation: question.explanation, source: question.source)

                                        if !correct && !pinsUndoRow {
                                            QuizUndoRow {
                                                quizSessionViewModel.undo(study: studyViewModel)
                                            }
                                        }
                                    }
                                    .accessibilityElement(children: .contain)
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

                    VStack(spacing: Spacing.sm) {
                        if case .revealed(let correct) = quizSessionViewModel.phase, !correct, pinsUndoRow {
                            QuizUndoRow {
                                quizSessionViewModel.undo(study: studyViewModel)
                            }
                        }

                        if case .revealed = quizSessionViewModel.phase {
                            Button {
                                quizSessionViewModel.advance(study: studyViewModel, sessions: sessionStore)
                                focusTarget = .question
                            } label: {
                                HStack(spacing: Spacing.sm) {
                                    Text("Next question")
                                    Image(systemName: "chevron.right")
                                        .accessibilityHidden(true)
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                            }
                            .appProminentButtonStyle(tint: Theme.primaryFill)
                        } else {
                            Button {
                                quizSessionViewModel.submit(study: studyViewModel)
                            } label: {
                                Text("Submit")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .appProminentButtonStyle(tint: Theme.primaryFill)
                            .disabled(quizSessionViewModel.selectedChoice == nil)
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.sm)
                .padding(.bottom, Spacing.base)
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
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
        .appAnimation(Motion.emphasized, value: quizSessionViewModel.phase)
        .onChange(of: quizSessionViewModel.phase) { _, newPhase in
            switch newPhase {
            case .revealed(let correct):
                AccessibilityNotification.Announcement(correct ? "Correct" : "Incorrect").post()
                Task {
                    await Task.yield()
                    focusTarget = .result
                }
            case .answering:
                focusTarget = .question
            case .finished:
                break
            }
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

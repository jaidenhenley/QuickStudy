//
//  QuizQuestionView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/1/26.
//

import SwiftUI

struct QuizQuestionView: View {
    @EnvironmentObject var viewModel: StudyViewModel

    let providedQuestions: [QuizQuestion]?

    @State private var questions: [QuizQuestion]
    @State private var currentIndex = 0
    @State private var score = 0
    @State private var selectedAnswer: Int? = nil
    @State private var hasSubmitted = false
    @State private var isFinished = false

    init(providedQuestions: [QuizQuestion]? = nil) {
        self.providedQuestions = providedQuestions
        _questions = State(initialValue: providedQuestions ?? [])
    }

    var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    
    var body: some View {
        VStack(spacing: 20) {
            if questions.isEmpty {
                Text("No approved cards yet")
                    .font(.headline)
                Text("Approve at least one flashcard to start a quiz.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else if !isFinished, let currentQuestion = currentQuestion {
                
                // header
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // prompt
                Text(currentQuestion.prompt)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                // Multi choices
                VStack(spacing: 12) {
                    ForEach(0..<currentQuestion.choices.count, id: \.self) { index in
                        Button {
                            if !hasSubmitted { selectedAnswer = index }
                        } label: {
                            HStack {
                                Text(currentQuestion.choices[index])
                                Spacer()
                                if hasSubmitted {
                                    icon(for: index)
                                }
                            }
                            .padding()
                            .background(color(for: index).opacity(0.15))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(color(for: index))
                            )
                        }
                        .disabled(hasSubmitted)
                    }
                }
                
                if hasSubmitted {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Explanation")
                            .font(.headline)
                        
                        Text(currentQuestion.explanation)
                            .font(.subheadline)
                    }
                    .padding()
                    .appGlassCard(cornerRadius: 10)
                    .transition(.opacity)
                    
                    Button("Next Question") {
                        nextQuestion()
                    }
                    .appProminentButtonStyle(tint: Theme.primary)
                    .padding(.top)
                } else {
                    Button("Submit Answer") {
                        submitAnswer()
                    }
                    .appProminentButtonStyle(tint: Theme.primary)
                    .disabled(selectedAnswer == nil)
                    .padding(.top)
                }
                
                Spacer()
            } else {
                //Results screeen
                VStack(spacing: 20) {
                    Text("Quiz Finished")
                        .font(.largeTitle)
                    
                    Text("Final Score: \(score) / \(questions.count)")
                    
                    Button("Restart Quiz") {
                        restartQuiz()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(BackgroundView())
        .animation(.default, value: hasSubmitted)
        .onAppear { loadQuestions() }
        .onChange(of: viewModel.flashcards) { _ in
            if providedQuestions == nil {
                loadQuestions()
            }
        }
    }

    private func loadQuestions() {
        if let providedQuestions {
            questions = providedQuestions
        } else {
            questions = viewModel.quizQuestions
        }
        if currentIndex >= questions.count {
            currentIndex = 0
        }
        if questions.isEmpty {
            isFinished = false
            hasSubmitted = false
            selectedAnswer = nil
        }
    }
    
    private func color(for index: Int) -> Color {
        guard hasSubmitted else {
            return selectedAnswer == index ? .blue : .gray
        }
        guard let currentQuestion = currentQuestion else { return .gray }
        
        if index == currentQuestion.correctIndex {
            return .green
        } else if index == selectedAnswer {
            return .red
        }
        return .gray
    }
    
    private func icon(for index: Int) -> Image? {
        guard let currentQuestion = currentQuestion else { return nil }

        if index == currentQuestion.correctIndex {
            return Image(systemName: "checkmark.circle.fill")
        } else if index == selectedAnswer {
            return Image(systemName: "x.circle.fill")
        }
        return nil
    }
    
    private func submitAnswer() {
        guard let currentQuestion = currentQuestion else { return }

        if selectedAnswer == currentQuestion.correctIndex {
            score += 1
        }
        hasSubmitted = true
    }
    
    private func nextQuestion() {
        guard !questions.isEmpty else { return }

        if currentIndex + 1 < questions.count {
            currentIndex += 1
            selectedAnswer = nil
            hasSubmitted = false
        } else {
            isFinished = true
        }
    }
    
    private func restartQuiz() {
        currentIndex = 0
        score = 0
        selectedAnswer = nil
        hasSubmitted = false
        isFinished = false
    }
       
    
    
}

#Preview {
    QuizQuestionView()
}

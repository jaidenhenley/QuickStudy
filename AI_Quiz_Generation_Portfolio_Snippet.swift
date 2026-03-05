// AI-Powered Quiz Generation - QuickStudy
// Intelligently generates multiple-choice questions from flashcards with context-aware distractor selection

import Foundation

struct QuizGenerator {

    // Generates multiple-choice quiz questions from approved flashcards with intelligent
    // distractor selection based on answer similarity and length matching
    func generateQuiz(from flashcards: [Flashcard]) -> [QuizQuestion] {
        let approvedCards = flashcards.filter { $0.approved }
        guard !approvedCards.isEmpty else { return [] }

        var questions: [QuizQuestion] = []
        questions.reserveCapacity(approvedCards.count)

        let allAnswers = uniqueAnswers(from: flashcards.map { $0.answer })

        for (index, card) in approvedCards.enumerated() {
            let correctAnswer = card.answer
            let normalizedCorrect = normalizedAnswer(correctAnswer)

            // Build pool of wrong answers excluding the correct one
            var pool = allAnswers.filter { normalizedAnswer($0) != normalizedCorrect }

            // Prefer distractors with similar length (within 10 characters)
            // to avoid trivially obvious wrong answers
            let similarLengthPool = pool.filter { abs($0.count - correctAnswer.count) <= 10 }
            if !similarLengthPool.isEmpty {
                pool = similarLengthPool
            }

            // Select 3 distractors randomly from the filtered pool
            var distractors: [String] = []
            for answer in pool.shuffled() {
                distractors.append(answer)
                if distractors.count == 3 { break }
            }

            // If insufficient unique answers exist, add fallback options
            if distractors.count < 3 {
                let fallbacks = ["None of the above", "Not sure", "Not listed"]
                for fallback in fallbacks {
                    let normalizedFallback = normalizedAnswer(fallback)
                    // Ensure fallback isn't duplicate or matching correct answer
                    if normalizedFallback != normalizedCorrect
                        && !distractors.contains(where: { normalizedAnswer($0) == normalizedFallback }) {
                        distractors.append(fallback)
                    }
                    if distractors.count == 3 { break }
                }
            }

            // Combine and shuffle choices
            var choices: [String] = [correctAnswer] + distractors
            choices.shuffle()

            let correctIndex = choices.firstIndex(of: correctAnswer) ?? 0
            let question = QuizQuestion(
                prompt: card.question,
                choices: choices,
                correctIndex: correctIndex,
                explanation: card.answer,
                sourceIndex: index
            )
            questions.append(question)
        }

        return questions
    }

    // Normalizes answers for comparison by trimming and lowercasing
    private func normalizedAnswer(_ answer: String) -> String {
        answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // Extracts unique answers using normalized comparison while preserving original formatting
    private func uniqueAnswers(from answers: [String]) -> [String] {
        var seen: Set<String> = []
        var result: [String] = []
        result.reserveCapacity(answers.count)

        for answer in answers {
            let key = normalizedAnswer(answer)
            if seen.insert(key).inserted {
                result.append(answer)
            }
        }
        return result
    }
}

// Supporting types
struct Flashcard {
    let question: String
    let answer: String
    let approved: Bool
}

struct QuizQuestion {
    let prompt: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let sourceIndex: Int
}

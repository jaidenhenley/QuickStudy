//
//  StudyViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import UIKit
import SwiftUI
import Combine

class StudyViewModel: ObservableObject {
    // MARK: - Settings
    @AppStorage("demoModeEnabled") var demoModeEnabled: Bool = true {
        didSet {
            applyDemoMode()
        }
    }

    // MARK: - Published state
    @Published var document: StudyDocument? = nil
    @Published var flashcards: [StudyCard] = []
    @Published var isGenerating: Bool = false
    @Published var isSpellCheckEnabled: Bool = true
    @Published var isHandwritingMode: Bool = false
    @Published var isUltraHandwritingMode: Bool = true
    @Published var generationErrorMessage: String? = nil
    @Published var lastRawText: String = ""
    @Published var lastCorrectedText: String = ""
    @Published var savedSets: [StudySet] = []
    @Published var activeSetID: UUID? = nil
    @Published var currentSourceType: StudySourceType = .scan

    init() {
        loadSavedSets()
    }
    
    // MARK: - Derived data
    var quizQuestions: [QuizQuestion] {
        let approvedCards = flashcards.filter { $0.approved }
        if approvedCards.isEmpty { return [] }

        var questions: [QuizQuestion] = []
        questions.reserveCapacity(approvedCards.count)

        let allAnswers = uniqueAnswers(from: flashcards.map { $0.answer })

        for (index, card) in approvedCards.enumerated() {
            let correctAnswer = card.answer
            let normalizedCorrect = normalizedAnswer(correctAnswer)

            var pool = allAnswers.filter { normalizedAnswer($0) != normalizedCorrect }
            let similarLengthPool = pool.filter { abs($0.count - correctAnswer.count) <= 10 }
            if !similarLengthPool.isEmpty {
                pool = similarLengthPool
            }

            var distractors: [String] = []
            for answer in pool.shuffled() {
                distractors.append(answer)
                if distractors.count == 3 { break }
            }

            if distractors.count < 3 {
                let fallbacks = ["None of the above", "Not sure", "Not listed"]
                for fallback in fallbacks {
                    let normalizedFallback = normalizedAnswer(fallback)
                    if normalizedFallback != normalizedCorrect
                        && !distractors.contains(where: { normalizedAnswer($0) == normalizedFallback }) {
                        distractors.append(fallback)
                    }
                    if distractors.count == 3 { break }
                }
            }

            var choices: [String] = [correctAnswer] + distractors
            choices.shuffle()

            let correctIndex = choices.firstIndex(of: correctAnswer) ?? 0
            let question = QuizQuestion(
                prompt: card.question,
                choices: choices,
                correctIndex: correctIndex,
                explanation: card.answer,
                sourceStartLine: index + 1,
                sourceEndLine: index + 1
            )
            questions.append(question)
        }

        return questions
    }

    // MARK: - Persistence
    var persistenceURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = documents.first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("SavedSets.json")
    }

    var currentDocument: StudyDocument? { document }

    private let spellCheckIgnoreList: Set<String> = [
        "swift",
        "swiftui",
        "uikit",
        "xcode",
        "ios",
        "ipad",
        "macos",
        "ocr",
        "quiz",
        "flashcard",
        "flashcards"
    ]
    
    
    // MARK: - Scan + generate
    @MainActor
    func loadScannedText(rawText: String, candidateLines: [[String]]? = nil) async {
        activeSetID = nil
        lastRawText = rawText

        var workingText: String
        if isSpellCheckEnabled {
            workingText = spellCorrect(rawText)
        } else {
            workingText = rawText
        }
#if canImport(FoundationModels)
        if isHandwritingMode, let repaired = await contextCorrect(workingText, candidateLines: candidateLines) {
            workingText = repaired
        }
#endif
        lastCorrectedText = workingText

        let lines = normalizeOCRLines(workingText)
        self.document = StudyDocument(title: "Scanned Document", lines: lines)
        self.flashcards = []
        await generateAICards(text: workingText)
    }

    @MainActor
    func generateAICards(text: String) async {
        self.isGenerating = true
        defer { self.isGenerating = false }
        generationErrorMessage = nil

#if canImport(FoundationModels)
        do {
            let cards = try await CardGenerator.generateAI(from: text)
            self.flashcards = cards
            saveCurrentSet()
        } catch {
#if DEBUG
            print("AI generation failed: \(error.localizedDescription)")
#endif
            let fallback = generateFallbackCards(from: text)
            self.flashcards = fallback
            saveCurrentSet()
        }
#else
        generationErrorMessage = "Apple Intelligence framework not available in this build."
#endif
    }

    private func generateFallbackCards(from text: String) -> [StudyCard] {
        let rawLines = text.components(separatedBy: .newlines)
        return generateCards(from: rawLines, approved: false, limit: 12)
    }

    private func generateDemoCards(from lines: [String]) -> [StudyCard] {
        return generateCards(from: lines, approved: true, limit: 12)
    }

    private func generateCards(from lines: [String], approved: Bool, limit: Int) -> [StudyCard] {
        var cleanedLines: [String] = []
        cleanedLines.reserveCapacity(lines.count)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                cleanedLines.append(trimmed)
            }
        }

        var cards: [StudyCard] = []
        cards.reserveCapacity(min(cleanedLines.count, limit))

        for line in cleanedLines.prefix(limit) {
            let question: String
            let answer: String

            if let separatorRange = line.range(of: ":") {
                let left = line[..<separatorRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let right = line[separatorRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                question = left.isEmpty ? "Explain this concept" : String(left)
                answer = right.isEmpty ? line : String(right)
            } else if let range = line.range(of: " is ") {
                let subject = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                question = subject.isEmpty ? "What is this?" : "What is \(subject)?"
                answer = line
            } else if let range = line.range(of: " are ") {
                let subject = line[..<range.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                question = subject.isEmpty ? "What are these?" : "What are \(subject)?"
                answer = line
            } else {
                let prefixWords = line.split(whereSeparator: { $0.isWhitespace }).prefix(6)
                let prefix = prefixWords.joined(separator: " ")
                question = prefix.isEmpty ? "Explain this concept" : "Explain: \(prefix)"
                answer = line
            }

            let card = StudyCard(question: question, answer: answer, approved: approved)
            cards.append(card)
        }

        return cards
    }

    @MainActor
    func generateCards() {
        guard let doc = document else { return }
        guard flashcards.isEmpty else { return }

        Task { @MainActor in
            await generateAICards(text: doc.lines.joined(separator: "\n"))
        }
    }
    // MARK: - Quiz helpers
    private func normalizedAnswer(_ answer: String) -> String {
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.lowercased()
    }

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

    #if canImport(FoundationModels)
    @MainActor
    private func contextCorrect(_ text: String, candidateLines: [[String]]?) async -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lines = text.components(separatedBy: .newlines)
        let fallbackCandidates = lines.map { [$0] }
        let allCandidates = candidateLines ?? fallbackCandidates
        let lineCount = min(lines.count, allCandidates.count)
        guard lineCount > 0 else { return nil }

        let chunkSize = isUltraHandwritingMode ? 8 : 20
        var correctedChunks: [String] = []
        let engine = CardGenerationEngine()

        for start in stride(from: 0, to: lineCount, by: chunkSize) {
            let end = min(start + chunkSize, lineCount)
            let lineSlice = Array(lines[start..<end])
            let candidateSlice = Array(allCandidates[start..<end])

            do {
                let corrected = try await engine.repairOCR(lines: lineSlice, candidates: candidateSlice)
                if let accepted = validatedCorrection(originalLines: lineSlice, correctedText: corrected) {
                    correctedChunks.append(accepted)
                } else {
                    correctedChunks.append(lineSlice.joined(separator: "\n"))
                }
            } catch {
#if DEBUG
                print("Context correction failed: \(error.localizedDescription)")
#endif
                correctedChunks.append(lineSlice.joined(separator: "\n"))
            }
        }

        return correctedChunks.joined(separator: "\n")
    }
    #endif

    func validatedCorrection(originalLines: [String], correctedText: String) -> String? {
        let correctedLines = correctedText.components(separatedBy: .newlines)
        guard correctedLines.count == originalLines.count else { return nil }

        let trimmedOriginal = originalLines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let trimmedCorrected = correctedLines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        let nonEmptyOriginal = trimmedOriginal.filter { !$0.isEmpty }
        let nonEmptyCorrected = trimmedCorrected.filter { !$0.isEmpty }
        if nonEmptyCorrected.count < max(1, nonEmptyOriginal.count / 2) {
            return nil
        }

        let uniqueCount = Set(trimmedCorrected).count
        if uniqueCount < max(2, trimmedCorrected.count / 3) {
            return nil
        }

        var repeatedRun = 1
        for index in 1..<trimmedCorrected.count {
            if trimmedCorrected[index] == trimmedCorrected[index - 1] {
                repeatedRun += 1
                if repeatedRun >= 3 { return nil }
            } else {
                repeatedRun = 1
            }
        }

        return correctedLines.joined(separator: "\n")
    }

    // MARK: - Spell check
    @MainActor
    func spellCorrect(_ text: String) -> String {
        let checker = UITextChecker()
        let currentLocale = Locale.current.identifier
        let language = UITextChecker.availableLanguages.contains(currentLocale)
            ? currentLocale
            : "en_US"

        let rawLines = text.components(separatedBy: .newlines)
        var correctedLines: [String] = []
        correctedLines.reserveCapacity(rawLines.count)

        for line in rawLines {
            let corrected = spellCorrectLine(line, checker: checker, language: language)
            correctedLines.append(corrected)
        }

        return correctedLines.joined(separator: "\n")
    }

    @MainActor
    func spellCorrectLine(_ line: String, checker: UITextChecker, language: String) -> String {
        var corrected = line
        var offset = 0

        while offset < corrected.utf16.count {
            let range = NSRange(location: offset, length: corrected.utf16.count - offset)
            let misspelledRange = checker.rangeOfMisspelledWord(
                in: corrected,
                range: range,
                startingAt: offset,
                wrap: false,
                language: language
            )

            if misspelledRange.location == NSNotFound {
                break
            }

            let word = (corrected as NSString).substring(with: misspelledRange)
            if shouldIgnoreWord(word) {
                offset = misspelledRange.location + misspelledRange.length
                continue
            }

            if let guesses = checker.guesses(forWordRange: misspelledRange, in: corrected, language: language),
               let bestGuess = guesses.first {
                corrected = (corrected as NSString).replacingCharacters(in: misspelledRange, with: bestGuess)
                offset = misspelledRange.location + bestGuess.utf16.count
            } else {
                offset = misspelledRange.location + misspelledRange.length
            }
        }

        return corrected
    }

    func shouldIgnoreWord(_ word: String) -> Bool {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }

        let normalized = trimmed.lowercased()
        if spellCheckIgnoreList.contains(normalized) {
            return true
        }

        return trimmed.rangeOfCharacter(from: .decimalDigits) != nil
    }


    func normalizeOCRLines(_ rawText: String) -> [String] {
        let pieces = rawText.components(separatedBy: .newlines)
        var rawLines: [String] = []
        rawLines.reserveCapacity(pieces.count)

        for piece in pieces {
            let trimmed = piece.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                rawLines.append(trimmed)
            }
        }

        if rawLines.isEmpty {
            return []
        }

        var shortLineCount = 0
        for line in rawLines where line.count <= 2 {
            shortLineCount += 1
        }

        if shortLineCount * 3 >= rawLines.count {
            let combined = rawLines.joined(separator: " ")
            let cleaned = combined.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            return [cleaned]
        }

        return rawLines
    }

    // MARK: - Saved sets
    func loadSavedSets() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            savedSets = try decoder.decode([StudySet].self, from: data)
        } catch {
            savedSets = []
        }
        ensurePresetSet()
        applyDemoMode()
    }

    func ensurePresetSet() {
        if savedSets.isEmpty {
            if demoModeEnabled {
                seedDemoSetsIfNeeded()
            }
            return
        }

        let hasOldDemo = savedSets.count == 1 && savedSets.first?.title == "SwiftUI/SpriteKit Demo"
        if hasOldDemo {
            savedSets.removeAll()
            if demoModeEnabled {
                seedDemoSetsIfNeeded()
            }
        }
    }

    private func seedDemoSetsIfNeeded() {
        let demoTitles = Set(["Human Interface Guidelines", "SwiftUI", "SpriteKit"])
        let existingDemoTitles = Set(savedSets.filter { isDemoSet($0) }.map { $0.title })
        guard existingDemoTitles != demoTitles else { return }

        let higDocument = StudyDocument(title: "Human Interface Guidelines", lines: DemoData.higLines)
        let swiftUIDocument = StudyDocument(title: "SwiftUI", lines: DemoData.swiftuiLines)
        let spriteKitDocument = StudyDocument(title: "SpriteKit", lines: DemoData.spriteKitLines)
        let higCards = generateDemoCards(from: DemoData.higLines)
        let swiftUICards = generateDemoCards(from: DemoData.swiftuiLines)
        let spriteKitCards = generateDemoCards(from: DemoData.spriteKitLines)
        let higSet = StudySet(title: higDocument.title, document: higDocument, cards: higCards, sourceType: .demo, isDemo: true)
        let swiftUISet = StudySet(title: swiftUIDocument.title, document: swiftUIDocument, cards: swiftUICards, sourceType: .demo, isDemo: true)
        let spriteKitSet = StudySet(title: spriteKitDocument.title, document: spriteKitDocument, cards: spriteKitCards, sourceType: .demo, isDemo: true)

        savedSets.removeAll { isDemoSet($0) }
        savedSets = [higSet, swiftUISet, spriteKitSet] + savedSets
        saveSavedSets()
    }

    func saveSavedSets() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedSets)
            try data.write(to: persistenceURL, options: [.atomic])
        } catch {
#if DEBUG
            print("Failed to save sets: \(error.localizedDescription)")
#endif
        }
    }

    func saveCurrentSet() {
        guard let document else { return }
        let title = document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Study Set"
            : document.title
        let cards = flashcards

        if let activeSetID,
           let index = savedSets.firstIndex(where: { $0.id == activeSetID }) {
            let existing = savedSets[index]
            savedSets[index] = StudySet(
                id: existing.id,
                title: existing.title,
                createdAt: existing.createdAt,
                updatedAt: Date(),
                document: document,
                cards: cards,
                sourceType: existing.sourceType,
                isDemo: existing.isDemo
            )
        } else {
            let newSet = StudySet(
                title: title,
                document: document,
                cards: cards,
                sourceType: currentSourceType,
                isDemo: false
            )
            savedSets.insert(newSet, at: 0)
            activeSetID = newSet.id
        }

        saveSavedSets()
    }

    func loadSet(_ set: StudySet) {
        document = set.document
        flashcards = set.cards
        activeSetID = set.id
        currentSourceType = set.sourceType
    }

    private func isDemoSet(_ set: StudySet) -> Bool {
        return set.isDemo || set.sourceType == .demo
    }

    func applyDemoMode() {
        if demoModeEnabled {
            seedDemoSetsIfNeeded()
            if let higSet = savedSets.first(where: { isDemoSet($0) && $0.title == "Human Interface Guidelines" }) {
                document = higSet.document
                flashcards = higSet.cards
                activeSetID = higSet.id
                currentSourceType = .demo
            }
        } else {
            let demoIDs = Set(savedSets.filter { isDemoSet($0) }.map { $0.id })
            if let activeSetID, demoIDs.contains(activeSetID) {
                self.activeSetID = nil
                self.document = nil
                self.flashcards = []
                self.currentSourceType = .scan
            } else if let document, ["Human Interface Guidelines", "SwiftUI", "SpriteKit"].contains(document.title) {
                self.document = nil
                self.flashcards = []
                self.currentSourceType = .scan
            }

            savedSets.removeAll { isDemoSet($0) }
            saveSavedSets()
        }
    }

    func deleteSet(_ set: StudySet) {
        savedSets.removeAll { $0.id == set.id }
        if activeSetID == set.id {
            activeSetID = nil
        }
        saveSavedSets()
    }

    func renameSet(id: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = savedSets.firstIndex(where: { $0.id == id }) else { return }
        savedSets[index].title = trimmed
        savedSets[index].updatedAt = Date()
        saveSavedSets()
    }
}

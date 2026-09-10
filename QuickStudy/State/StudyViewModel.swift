//
//  StudyViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import OSLog
import UIKit
import SwiftUI

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.henley.jaiden.QuickStudy",
    category: "StudyViewModel"
)

@Observable
class StudyViewModel {
    // MARK: - Settings
    @ObservationIgnored
    @AppStorage("demoModeEnabled") var demoModeEnabled: Bool = false {
        didSet {
            applyDemoMode()
        }
    }
    
    var aiSettings: AISettings = AISettings()

    // MARK: - Published state
   var document: StudyDocument? = nil
   var flashcards: [StudyCard] = []
   var isGenerating: Bool = false
   var isSpellCheckEnabled: Bool = true
   var isHandwritingMode: Bool = false
   var isUltraHandwritingMode: Bool = true
   var generationErrorMessage: String? = nil
   var lastRawText: String = ""
   var lastCorrectedText: String = ""
   var savedSets: [StudySet] = []
   var activeSetID: UUID? = nil
   var currentSourceType: StudySourceType = .scan
   var isTodaySession: Bool = false

    @ObservationIgnored private var hasUnsavedChanges = false

    init() {
        loadSavedSets()
    }

    func loadTodaySession(asOf date: Date = Date(), calendar: Calendar = .current) {
        flashcards = savedSets
            .flatMap(\.cards)
            .filter { $0.isDue(asOf: date, calendar: calendar) }
        isTodaySession = true
    }

    func box(for cardID: UUID) -> Int? {
        savedSets.lazy.compactMap { $0.cards.first { $0.id == cardID }?.box }.first
    }

    func restoreBox(_ box: Int, missCountDelta: Int, for cardID: UUID) {
        guard let setIndex = savedSets.firstIndex(where: { $0.cards.contains { $0.id == cardID } }),
              let cardIndex = savedSets[setIndex].cards.firstIndex(where: { $0.id == cardID }) else { return }
        savedSets[setIndex].cards[cardIndex].box = box
        savedSets[setIndex].cards[cardIndex].missCount = max(0, savedSets[setIndex].cards[cardIndex].missCount + missCountDelta)
        savedSets[setIndex].cards[cardIndex].dueDate = ReviewSchedule.newDueDate(forBox: box)
        hasUnsavedChanges = true
    }

    /// Questions carry their set, source and box so nothing has to be looked back up mid-session.
    func sessionQuestions(for cards: [StudyCard]) -> [QuizQuestion] {
        cards.compactMap { card in
            guard let set = savedSets.first(where: { $0.cards.contains { $0.id == card.id } }) else { return nil }

            var wrong = card.distractors
            if wrong.count < 3 {
                // Cards from before distractors existed, or from the non-AI fallback.
                wrong += savedSets
                    .flatMap(\.cards)
                    .map(\.answer)
                    .filter { $0.caseInsensitiveCompare(card.answer) != .orderedSame }
                    .shuffled()
                    .prefix(3 - wrong.count)
            }

            var choices = [card.answer] + wrong.prefix(3)
            if choices.count < 2 { choices.append("Not applicable") }
            choices.shuffle()

            return QuizQuestion(
                cardID: card.id,
                setID: set.id,
                prompt: card.question,
                choices: choices,
                correctIndex: choices.firstIndex(of: card.answer) ?? 0,
                explanation: card.explanation ?? card.answer,
                source: card.source,
                setTitle: set.title,
                boxBefore: card.box
            )
        }
    }

    /// Session cards come from many sets, so the answer is written back by card id.
    func recordAnswer(for cardID: UUID, correct: Bool, on date: Date = Date()) {
        guard let setIndex = savedSets.firstIndex(where: { set in
            set.cards.contains { $0.id == cardID }
        }), let cardIndex = savedSets[setIndex].cards.firstIndex(where: { $0.id == cardID }) else {
            return
        }

        savedSets[setIndex].cards[cardIndex].recordAnswer(correct: correct, on: date)
        savedSets[setIndex].updatedAt = date

        if let workingIndex = flashcards.firstIndex(where: { $0.id == cardID }) {
            flashcards[workingIndex] = savedSets[setIndex].cards[cardIndex]
        }

        hasUnsavedChanges = true
    }

    /// Structural edits (save, rename, delete) still write immediately — they are rare
    /// and user-initiated. Only per-answer churn is deferred, since each write re-encodes
    /// the entire library including every document's source text.
    func flushPendingChanges() {
        guard hasUnsavedChanges else { return }
        saveSavedSets()
    }

    // MARK: - AI Quiz Generation

    

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
    func makeDraft(
        from extracted: ExtractedDocument,
        title: String,
        sourceType: StudySourceType
    ) async -> DraftSet? {
        var allLines: [String] = []
        var pageBreaks: [Int] = []

        for page in extracted.pages {
            pageBreaks.append(allLines.count)
            var working = isSpellCheckEnabled ? spellCorrect(page.text) : page.text
            if isHandwritingMode,
               let repaired = await contextCorrect(
                   working,
                   candidateLines: page.candidates.isEmpty ? nil : page.candidates
               ) {
                working = repaired
            }
            allLines.append(contentsOf: normalizeOCRLines(working))
        }

        let document = StudyDocument(
            title: title,
            lines: allLines,
            pageBreaks: extracted.pages.count > 1 ? pageBreaks : nil
        )
        let cards = await generateCards(for: document, countsAgainstAllowance: true)
        guard !cards.isEmpty else { return nil }

        return DraftSet(title: title, document: document, cards: cards, sourceType: sourceType)
    }

    @MainActor
    func makePastedDraft(_ text: String) async -> DraftSet? {
        await makeDraft(
            from: ExtractedDocument(pages: [.init(text: text, candidates: [])]),
            title: "Pasted Notes",
            sourceType: .paste
        )
    }

    /// Regenerate re-rolls the same document, so it does not spend another generation.
    @MainActor
    func generateCards(for document: StudyDocument, countsAgainstAllowance: Bool) async -> [StudyCard] {
        isGenerating = true
        defer { isGenerating = false }
        generationErrorMessage = nil

        let text = document.lines.joined(separator: "\n")
#if canImport(FoundationModels)
        do {
            let cards = try await CardGenerator.generateAI(from: text, document: document, settings: aiSettings)
            if countsAgainstAllowance { GenerationAllowance.recordGeneration() }
            return cards
        } catch {
            logger.error("AI generation failed: \(error.localizedDescription)")
            return generateFallbackCards(from: text)
        }
#else
        generationErrorMessage = "Apple Intelligence framework not available in this build."
        return generateFallbackCards(from: text)
#endif
    }

    @MainActor
    func generateSuggestedCards(for setID: UUID, topic: String, count: Int) async {
        guard let index = savedSets.firstIndex(where: { $0.id == setID }) else { return }

        isGenerating = true
        defer { isGenerating = false }
        generationErrorMessage = nil

        let sourceText = savedSets[index].document.lines.joined(separator: "\n")

        do {
            let cards = try await CardGenerator.generateTopicCards(
                from: sourceText,
                document: savedSets[index].document,
                topic: topic,
                count: count,
                settings: aiSettings
            )
            guard !cards.isEmpty else {
                generationErrorMessage = "Couldn't find enough about \(topic) in this set to make new cards."
                return
            }
            savedSets[index].cards.append(contentsOf: cards)
            savedSets[index].updatedAt = Date()
            GenerationAllowance.recordGeneration()
            saveSavedSets()
        } catch {
            generationErrorMessage = "Couldn't generate cards on \(topic). Please try again."
        }
    }

    @MainActor
    func generateAICards(text: String) async {
        self.isGenerating = true
        defer { self.isGenerating = false }
        generationErrorMessage = nil

#if canImport(FoundationModels)
        do {
            let cards = try await CardGenerator.generateAI(
                from: text,
                document: document ?? StudyDocument(title: "", lines: []),
                settings: aiSettings
            )
            GenerationAllowance.recordGeneration()
            self.flashcards = cards
            saveCurrentSet()
        } catch {
            logger.error("AI generation failed: \(error.localizedDescription)")
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
        return generateCards(from: rawLines, limit: 12)
    }

    private func generateCards(from lines: [String], limit: Int) -> [StudyCard] {
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

            let card = StudyCard(question: question, answer: answer)
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

    @MainActor
    private func contextCorrect(_ text: String, candidateLines: [[String]]?) async -> String? {
#if canImport(FoundationModels)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let lines = text.components(separatedBy: .newlines)
        let fallbackCandidates = lines.map { [$0] }
        let allCandidates = candidateLines ?? fallbackCandidates
        let lineCount = min(lines.count, allCandidates.count)
        guard lineCount > 0 else { return nil }

        let chunkSize = isUltraHandwritingMode ? 8 : 20
        var correctedChunks: [String] = []
        let engine = OnDeviceCardGenerationEngine()

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
                correctedChunks.append(lineSlice.joined(separator: "\n"))
            }
        }

        return correctedChunks.joined(separator: "\n")
#else
        return nil
#endif
    }

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
            logger.error("Failed to load saved sets: \(error.localizedDescription)")
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
        // Always remove and regenerate demo sets to ensure they have the latest configuration
        savedSets.removeAll { isDemoSet($0) }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let demoSets = DemoData.sets.map { spec in
            let cards = spec.cards.map { card in
                StudyCard(
                    question: card.question,
                    answer: card.answer,
                    missCount: card.missCount,
                    box: card.box,
                    dueDate: card.dueInDays.flatMap { calendar.date(byAdding: .day, value: $0, to: today) },
                    lastReviewedAt: card.box > 0 ? today : nil
                )
            }
            return StudySet(
                title: spec.title,
                document: StudyDocument(title: spec.title, lines: spec.lines),
                cards: cards,
                sourceType: .demo,
                isDemo: true
            )
        }

        savedSets = demoSets + savedSets
        saveSavedSets()
    }

    func saveSavedSets() {
        hasUnsavedChanges = false
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(savedSets)
            try data.write(to: persistenceURL, options: [.atomic])
        } catch {
            logger.error("Failed to save sets: \(error.localizedDescription)")
        }
    }

    func saveCurrentSet() {
        guard !isTodaySession else { return }
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
        isTodaySession = false
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

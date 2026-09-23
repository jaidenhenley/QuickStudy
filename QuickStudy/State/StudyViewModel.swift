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
    var store: StoreController = StoreController()
    var analytics: AnalyticsRecorder = AnalyticsRecorder()
    let generationProgress = GenerationProgress()

    var userSetCount: Int { savedSets.filter { !$0.isDemo }.count }

    // MARK: - Published state
   var document: StudyDocument? = nil
   var flashcards: [StudyCard] = []
   var isGenerating: Bool = false
   var isSpellCheckEnabled: Bool = true
   var isHandwritingMode: Bool = false
   var isUltraHandwritingMode: Bool = true
   private(set) var lastGenerationWasTruncated = false
   private(set) var lastGenerationProvenance: GenerationProvenance?
   var generationErrorMessage: String? = nil
   var generationErrorCode: String? = nil
   var savedSets: [StudySet] = []
   var activeSetID: UUID? = nil

    @ObservationIgnored private var hasUnsavedChanges = false

    init() {
        loadSavedSets()
    }

    func loadTodaySession(asOf date: Date = Date(), calendar: Calendar = .current) {
        flashcards = savedSets
            .flatMap(\.cards)
            .filter { $0.isDue(asOf: date, calendar: calendar) }
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

            var wrong = DistractorRefiner.refine(
                card.distractors,
                answer: card.answer,
                source: card.source?.excerpt ?? card.answer
            )

            if wrong.count < 3 {
                // Cards from before distractors existed, and cards whose options were
                // refined away. Same page first, then same set: topical neighbours make
                // better wrong answers than random ones.
                let samePage = set.cards.filter {
                    $0.id != card.id && $0.source?.page != nil && $0.source?.page == card.source?.page
                }
                let pool = (samePage + set.cards.filter { $0.id != card.id }).map(\.answer)
                wrong += DistractorRefiner.backfill(
                    pool, answer: card.answer, existing: wrong, needed: 3 - wrong.count
                )
            }

            if wrong.count < 3 {
                let library = savedSets.flatMap(\.cards).map(\.answer).shuffled()
                wrong += DistractorRefiner.backfill(
                    library, answer: card.answer, existing: wrong, needed: 3 - wrong.count
                )
            }

            // The quality filters can still empty the pool for an unusual answer. Four
            // weak options beat two good ones, so this stage accepts anything that is
            // not a duplicate.
            if wrong.count < 3 {
                let library = savedSets.flatMap(\.cards).map(\.answer).shuffled()
                wrong += DistractorRefiner.pad(
                    library, answer: card.answer, existing: wrong, needed: 3 - wrong.count
                )
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

    // MARK: - Persistence
    var persistenceURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = documents.first ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent("SavedSets.json")
    }

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

        return DraftSet(
            title: title,
            document: document,
            cards: cards,
            sourceType: sourceType,
            wasTruncated: lastGenerationWasTruncated,
            provenance: lastGenerationProvenance
        )
    }

    /// Regenerate re-rolls the same document, so it does not spend another generation.
    @MainActor
    func generateCards(for document: StudyDocument, countsAgainstAllowance: Bool) async -> [StudyCard] {
        isGenerating = true
        defer { isGenerating = false }
        generationErrorMessage = nil
        generationErrorCode = nil

        let text = document.lines.joined(separator: "\n")
        lastGenerationWasTruncated = false
        lastGenerationProvenance = nil
#if canImport(FoundationModels)
        do {
            return try await draft(text: text, document: document, countsAgainstAllowance: countsAgainstAllowance)
        } catch CardGenerationError.notSubscribed {
            // The server is the authority on entitlement. Whatever the app believes, a
            // refusal means this iPhone drafts instead — losing hosted quality is better
            // than losing the import.
            if !store.isPro { store.markFreeHostedGenerationUsed() }
            do {
                return try await draft(text: text, document: document, countsAgainstAllowance: countsAgainstAllowance)
            } catch {
                logger.error("AI generation failed: \(String(describing: type(of: error))) — \(error.localizedDescription)")
                generationErrorMessage = Self.message(for: error)
                generationErrorCode = Self.code(for: error)
                return []
            }
        } catch {
            logger.error("AI generation failed: \(String(describing: type(of: error))) — \(error.localizedDescription)")
            generationErrorMessage = Self.message(for: error)
            generationErrorCode = Self.code(for: error)
            return []
        }
#else
        generationErrorMessage = "Apple Intelligence framework not available in this build."
        generationErrorCode = "QS-600"
        return []
#endif
    }

    @MainActor
    private func draft(
        text: String,
        document: StudyDocument,
        countsAgainstAllowance: Bool
    ) async throws -> [StudyCard] {
        let engine = try AIController.makeGenerator(settings: aiSettings, store: store, progress: generationProgress)
        lastGenerationWasTruncated = engine.sourceChunkLimit.map { text.count > $0 } ?? false
        let startedAt = Date()
        generationProgress.begin(
            expectedSeconds: engine.expectedSeconds,
            readsWholeDocument: engine.sourceChunkLimit == nil
        )
        defer { generationProgress.end() }
        let cards = try await CardGenerator.generateAI(from: text, document: document, engine: engine)
        lastGenerationProvenance = engine.provenance
        if countsAgainstAllowance && engine.countsAgainstAllowance { GenerationAllowance.recordGeneration() }
        analytics.record(.firstGenerationCompleted(durationBucket: Self.durationBucket(since: startedAt)))
        return cards
    }

    /// 0: under 5s, 1: under 10s, 2: under 20s, 3: under 45s, 4: slower.
    private static func durationBucket(since start: Date, now: Date = Date()) -> Int {
        switch now.timeIntervalSince(start) {
        case ..<5: return 0
        case ..<10: return 1
        case ..<20: return 2
        case ..<45: return 3
        default: return 4
        }
    }

    /// An unrecognised error type used to render as QS-503, indistinguishable from a real
    /// generation failure. The suffix names the type so a report points at the cause.
    private static func code(for error: Error) -> String {
        if let known = error as? CardGenerationError { return known.code }
        let bridged = error as NSError
        let domain = bridged.domain.split(separator: ".").last.map(String.init) ?? bridged.domain
        return CardGenerationError.unexpected("\(domain)-\(bridged.code)").code
    }

    /// A raw URLError description is not user-facing copy.
    private static func message(for error: Error) -> String {
        (error as? CardGenerationError)?.errorDescription
            ?? "Couldn't draft cards from this. Try a different source."
    }

    @MainActor
    func generateSuggestedCards(for setID: UUID, topic: String, count: Int) async {
        guard let index = savedSets.firstIndex(where: { $0.id == setID }) else { return }

        isGenerating = true
        defer { isGenerating = false }
        generationErrorMessage = nil
        generationErrorCode = nil

        let sourceText = savedSets[index].document.lines.joined(separator: "\n")

        do {
            let engine = try AIController.makeGenerator(settings: aiSettings, store: store)
            let cards = try await CardGenerator.generateTopicCards(
                from: sourceText,
                document: savedSets[index].document,
                topic: topic,
                count: count,
                engine: engine
            )
            guard !cards.isEmpty else {
                generationErrorMessage = "Couldn't find enough about \(topic) in this set to make new cards."
                generationErrorCode = "QS-506"
                return
            }
            savedSets[index].cards.append(contentsOf: cards)
            savedSets[index].updatedAt = Date()
            if engine.countsAgainstAllowance { GenerationAllowance.recordGeneration() }
            saveSavedSets()
        } catch {
            generationErrorMessage = Self.message(for: error)
            generationErrorCode = Self.code(for: error)
        }
    }

    // MARK: - Quiz helpers

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

    func loadSet(_ set: StudySet) {
        document = set.document
        flashcards = set.cards
        activeSetID = set.id
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
            }
        } else {
            let demoIDs = Set(savedSets.filter { isDemoSet($0) }.map { $0.id })
            if let activeSetID, demoIDs.contains(activeSetID) {
                self.activeSetID = nil
                self.document = nil
                self.flashcards = []
            } else if let document, ["Human Interface Guidelines", "SwiftUI", "SpriteKit"].contains(document.title) {
                self.document = nil
                self.flashcards = []
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

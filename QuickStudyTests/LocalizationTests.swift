//
//  LocalizationTests.swift
//  QuickStudyTests
//

import Foundation
import NaturalLanguage
import Testing
@testable import QuickStudy

struct LocalizationCatalogTests {
    static let languages = ["es-419", "es-ES", "fr", "de", "ja", "ko", "pt-BR"]
    static let tables = ["Localizable", "InfoPlist", "SampleSet"]

    private static func catalog(_ table: String) throws -> [String: [String: Any]] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("QuickStudy/\(table).xcstrings"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(json["strings"] as? [String: [String: Any]])
    }

    /// Every text a localization can show: the plain value, each plural form, each device
    /// variant, and each substitution's plural forms.
    private static func values(of localization: [String: Any]) -> [String] {
        var found: [String] = []
        if let unit = localization["stringUnit"] as? [String: Any], let value = unit["value"] as? String {
            found.append(value)
        }
        let variations = localization["variations"] as? [String: Any]
        if let plural = variations?["plural"] as? [String: [String: Any]] {
            found += plural.values.flatMap(values)
        }
        if let device = variations?["device"] as? [String: [String: Any]] {
            found += device.values.flatMap(values)
        }
        if let substitutions = localization["substitutions"] as? [String: [String: Any]] {
            found += substitutions.values.flatMap(values)
        }
        return found
    }

    /// A string that says "iPhone" carries an iPad variant; each is checked as its own form.
    private static func deviceForms(of localization: [String: Any]) -> [[String: Any]] {
        let device = (localization["variations"] as? [String: Any])?["device"] as? [String: [String: Any]]
        return device.map { Array($0.values) } ?? [localization]
    }

    @Test(arguments: tables)
    func everyStringIsTranslatedIntoEveryLanguage(table: String) throws {
        for (key, entry) in try Self.catalog(table) where entry["shouldTranslate"] as? Bool != false {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for language in Self.languages {
                let texts = localizations[language].map(Self.values) ?? []
                #expect(!texts.isEmpty, "\(table): \(language) is missing \"\(key)\"")
                #expect(texts.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }, "\(table): \(language) has an empty \"\(key)\"")
            }
        }
    }

    @Test(arguments: tables)
    func noTranslationUsesAnEmDash(table: String) throws {
        for (key, entry) in try Self.catalog(table) {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            for (language, localization) in localizations {
                #expect(Self.values(of: localization).allSatisfy { !$0.contains("\u{2014}") }, "\(language): \"\(key)\"")
            }
        }
    }

    /// A translation that drops or retypes an argument prints the wrong value or crashes.
    @Test func translationsKeepEveryFormatArgument() throws {
        let specifier = try NSRegularExpression(pattern: #"%(?:(\d+)\$)?(lld|ld|d|@|f)"#)
        func arguments(in text: String) -> [Int: String] {
            var found: [Int: String] = [:]
            var implicit = 0
            let range = NSRange(text.startIndex..., in: text)
            for match in specifier.matches(in: text, range: range) {
                let kind = (text as NSString).substring(with: match.range(at: 2)) == "@" ? "object" : "number"
                let position: Int
                if match.range(at: 1).location != NSNotFound {
                    position = Int((text as NSString).substring(with: match.range(at: 1))) ?? 0
                } else {
                    implicit += 1
                    position = implicit
                }
                found[position] = kind
            }
            return found
        }

        for (key, entry) in try Self.catalog("Localizable") {
            let localizations = entry["localizations"] as? [String: [String: Any]] ?? [:]
            // Keys such as libraryFilter.all carry their English in the catalog, not in the key.
            let english = localizations["en"]
                .flatMap { Self.deviceForms(of: $0).first }
                .flatMap { ($0["stringUnit"] as? [String: Any])?["value"] as? String } ?? key
            let expected = arguments(in: english.contains("%#@") ? key : english)
            for (language, localization) in localizations where language != "en" {
                var substituted: [Int: String] = [:]
                let substitutions = localization["substitutions"] as? [String: [String: Any]] ?? [:]
                for substitution in substitutions.values {
                    if let position = substitution["argNum"] as? Int { substituted[position] = "number" }
                }
                for form in Self.deviceForms(of: localization) {
                    var used = substituted
                    let unit = (form["stringUnit"] as? [String: Any])?["value"] as? String
                    let plural = (form["variations"] as? [String: Any])?["plural"] as? [String: [String: Any]] ?? [:]
                    for text in [unit].compactMap({ $0 }) + plural.values.flatMap(Self.values) {
                        used.merge(arguments(in: text)) { current, _ in current }
                    }
                    #expect(used == expected, "\(language): \"\(key)\" uses \(used), English uses \(expected)")
                }
            }
        }
    }
}

struct LocalizedCopyTests {
    private func bundle(_ language: String) throws -> Bundle {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"), "No \(language).lproj in the app")
        return try #require(Bundle(path: path))
    }

    @Test(arguments: LocalizationCatalogTests.languages)
    func theAppShipsEachLanguage(language: String) throws {
        let translated = try bundle(language).localizedString(forKey: "Start Session", value: nil, table: nil)
        #expect(translated != "Start Session")
        let sample = try bundle(language).localizedString(forKey: "Photosynthesis", value: nil, table: "SampleSet")
        #expect(sample != "Photosynthesis")
    }

    @Test func englishPluralsReadAsTheyDidBeforeLocalization() {
        #expect(String(localized: "\(1) cards drafted") == "1 card drafted")
        #expect(String(localized: "\(3) cards drafted") == "3 cards drafted")
        #expect(String(localized: "Save \(1) Cards") == "Save 1 Card")
        #expect(String(localized: "\(1) cards from \("Notes")") == "1 card from Notes")
        #expect(String(localized: "\(2) cards drafted from \(3) pages") == "2 cards drafted from 3 pages")
        #expect(String(localized: "Missed \(1) times · Drill") == "Missed 1 time · Drill")
    }

    @Test func spanishPluralsFollowTheCount() throws {
        let spanish = try bundle("es-419")
        let format = spanish.localizedString(forKey: "%lld cards drafted", value: nil, table: nil)
        let one = String(format: format, locale: Locale(identifier: "es_MX"), 1)
        let many = String(format: format, locale: Locale(identifier: "es_MX"), 4)
        #expect(one != many)
        #expect(one.contains("1") && many.contains("4"))
    }

    @Test func quotaReasonsHaveTheirOwnCopy() {
        let reasons: [HostedQuotaReason] = [
            .rateLimited, .monthlyLimitReached, .documentExceedsRemaining(needed: 4, remaining: 2),
            .freeGenerationInProgress, .unspecified
        ]
        #expect(Set(reasons.map(\.message)).count == reasons.count)
        #expect(HostedQuotaReason.documentExceedsRemaining(needed: 4, remaining: 2).message
            == "This document needs 4 generations and you have 2 left this month. Try importing fewer pages.")
        #expect(HostedQuotaReason.documentExceedsRemaining(needed: 1, remaining: 0).message.contains("1 generation and"))
    }
}

struct SourceLanguageTests {
    private let spanish = "La fotosíntesis es el proceso que usan las plantas para convertir la energía de la luz en energía química."
    private let japanese = "光合成は、植物や藻類が光エネルギーを化学エネルギーに変換し、グルコースとして蓄える過程である。"
    private let korean = "광합성은 식물과 조류가 빛 에너지를 화학 에너지로 바꾸어 포도당에 저장하는 과정이다."

    @Test func thePromptNamesTheLanguageOfTheSource() {
        #expect(SourceLanguage.promptRule(for: spanish).contains("Spanish"))
        #expect(SourceLanguage.promptRule(for: japanese).contains("Japanese"))
        #expect(SourceLanguage.promptRule(for: "Photosynthesis turns light energy into chemical energy.").contains("English"))
        #expect(PromptBuilder.flashcardPrompt(from: spanish).contains("Write every question, answer, explanation and wrong answer in Spanish"))
    }

    @Test func anUndetectableSourceStillAsksForItsOwnLanguage() {
        #expect(SourceLanguage.promptRule(for: "42 17 9").contains("same language as the source"))
    }

    @Test func wordsAreCountedWithoutSpaces() {
        #expect(SourceLanguage.wordCount(in: "The heart has four chambers.") == 5)
        #expect(SourceLanguage.wordCount(in: japanese) > 10)
    }

    @MainActor
    @Test func spellCheckFollowsThePageNotTheIPhone() {
        let language = StudyViewModel.spellCheckLanguage(for: spanish)
        #expect(language?.hasPrefix("es") == true)
    }

    @Test func distractorsInUnspacedScriptsSurviveTheSourceCheck() {
        let answer = "葉緑体で行われる"
        let options = ["ミトコンドリアで行われる", "細胞核で行われる", "リボソームで行われる"]
        let source = "光合成は葉緑体で行われる。ミトコンドリアは呼吸を行い、細胞核は遺伝情報を保持し、リボソームはタンパク質を合成する。"
        #expect(DistractorRefiner.refine(options, answer: answer, source: source) == options)

        let koreanAnswer = "엽록체에서 일어난다"
        let koreanOptions = ["미토콘드리아에서 일어난다", "세포핵에서 일어난다", "리보솜에서 일어난다"]
        let koreanSource = "광합성은 엽록체에서 일어난다. 미토콘드리아는 호흡을 하고, 세포핵은 유전 정보를 보관하며, 리보솜은 단백질을 합성한다."
        #expect(DistractorRefiner.refine(koreanOptions, answer: koreanAnswer, source: koreanSource) == koreanOptions)
    }

    @Test func aRestatedAnswerIsStillRejectedInJapanese() {
        let kept = DistractorRefiner.refine(["葉緑体で行われる。"], answer: "葉緑体で行われる", source: nil)
        #expect(kept.isEmpty)
    }

    @Test func aLongSentenceWithoutSpacesIsSplitToFitTheModel() {
        let long = String(repeating: "光合成は植物が光エネルギーを化学エネルギーに変換する過程であり", count: 20)
        let sentences = SentenceIndexer.sentences(in: long, maxLength: 200)
        #expect(sentences.count > 1)
        #expect(sentences.allSatisfy { $0.text.count <= 200 })
    }

    @MainActor
    @Test func suggestionTopicsDropTheQuestionWordInEveryLanguage() {
        #expect(TodayViewModel.topic(from: "What is chlorophyll?") == "chlorophyll")
        #expect(TodayViewModel.topic(from: "¿Qué es la clorofila?") == "la clorofila")
        #expect(TodayViewModel.topic(from: "Qu’est-ce que la chlorophylle\u{00A0}?") == "la chlorophylle")
        #expect(TodayViewModel.topic(from: "Was ist Chlorophyll?") == "Chlorophyll")
        #expect(TodayViewModel.topic(from: "O que é a clorofila?") == "a clorofila")
        #expect(TodayViewModel.topic(from: "クロロフィルとは何か？") == "クロロフィル")
        #expect(TodayViewModel.topic(from: "엽록소란 무엇인가?") == "엽록소")
    }

    @Test func titlesComeFromTheSubjectInOtherLanguages() {
        let spanishNotes = "La fotosíntesis es el proceso que usan las plantas, las algas y algunas bacterias para convertir la luz."
        #expect(SetTitleSuggester.title(from: [spanishNotes]) == "La fotosíntesis")
        let title = SetTitleSuggester.title(from: [japanese + japanese])
        #expect(title == "光合成")
    }
}

struct LocalizedSampleSetTests {
    /// The quiz backfills dropped distractors from other cards' answers, which would show a
    /// right answer as a wrong option, so every translated distractor must pass the refiner.
    @Test(arguments: LocalizationCatalogTests.languages)
    func translatedDistractorsSurviveTheRefiner(language: String) throws {
        let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        func translated(_ english: String) -> String {
            bundle.localizedString(forKey: english, value: nil, table: "SampleSet")
        }
        // Tests run in English, so DemoData's strings are the catalog keys.
        for card in DemoData.set.cards {
            let answer = translated(card.answer)
            let distractors = card.distractors.map(translated)
            #expect(answer != card.answer, "\(language): \(card.answer) is not translated")
            let kept = DistractorRefiner.refine(distractors, answer: answer, source: nil)
            #expect(kept == distractors, "\(language): \(answer) keeps \(kept) of \(distractors)")
        }
    }
}

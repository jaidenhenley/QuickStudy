//
//  EngineComparisonTests.swift
//  QuickStudyTests
//

import Foundation
import StoreKit
import Testing
@testable import QuickStudy

/// Drafts the same documents with every engine and attaches a blind side-by-side report.
/// Off unless `QS_COMPARE_ENGINES=1`: it spends Private Cloud Compute quota and Pro
/// generations, and needs a physical iOS 27 device with a Sandbox Pro subscription.
@Suite(.enabled(if: ProcessInfo.processInfo.environment["QS_COMPARE_ENGINES"] == "1"))
@MainActor
struct EngineComparisonTests {
    /// Engines are built fresh per document: the skipped-section count lives on the
    /// engine, and a shared one would carry it from one document to the next.
    private struct Contender {
        let name: String
        let makeEngine: @MainActor () throws -> any CardGenerating
    }

    @MainActor
    private struct Run {
        let cards: [StudyCard]
        let skippedSections: Int
        let seconds: Double
        let failure: String?

        var locatedCount: Int { cards.filter { $0.source != nil }.count }
        var fullDistractorCount: Int { cards.filter { $0.distractors.count == 3 }.count }
        var missingExplanationCount: Int { cards.filter { $0.explanation == nil }.count }
    }

    @Test(.timeLimit(.minutes(30)))
    func draftFixturesWithEveryEngine() async throws {
        try #require(
            PrivateCloud.makeEngine(progress: nil) != nil,
            "Private Cloud Compute isn't ready: run on an iOS 27 device with the capability added."
        )
        let transaction = try #require(
            await Self.proTransactionJWS(),
            "No Pro subscription on this device: buy one with a Sandbox account first."
        )
        let contenders = [
            Contender(name: "On-device") { try AIController.makeOnDeviceGenerator() },
            Contender(name: "Private Cloud Compute") {
                if let engine = PrivateCloud.makeEngine(progress: nil) { return engine }
                if case .quotaReached(let resetsAt) = PrivateCloud.status {
                    throw CardGenerationError.privateCloudQuotaReached(resetsAt: resetsAt)
                }
                throw CardGenerationError.privateCloudUnavailable
            },
            Contender(name: "Cloudflare") {
                HostedCardGenerationEngine(api: .configured(), transaction: transaction, onRemaining: { _ in })
            }
        ].shuffled()

        var report = "# Engine comparison\n\nEngines are labelled A, B and C. The key is at the end.\n"
        for document in try Self.documents() {
            report += "\n## \(document.title)\n\n| | Cards | Source found | 3 distractors | No explanation | Skipped sections | Seconds | Failure |\n|---|---|---|---|---|---|---|---|\n"
            var cardSections = ""
            for (index, contender) in contenders.enumerated() {
                let label = Self.label(index)
                let run = await Self.draft(document, with: contender)
                report += "| \(label) | \(run.cards.count) | \(run.locatedCount) | \(run.fullDistractorCount) | \(run.missingExplanationCount) | \(run.skippedSections) | \(String(format: "%.1f", run.seconds)) | \(run.failure ?? "") |\n"
                cardSections += "\n### \(document.title) · \(label)\n"
                for card in run.cards {
                    cardSections += "\n**Q:** \(card.question)\n**A:** \(card.answer)\n"
                    cardSections += "Wrong: \(card.distractors.joined(separator: " / "))\n"
                    cardSections += "Why: \(card.explanation ?? "none")\n"
                    cardSections += "Source: \(card.source?.excerpt ?? "not found")\n"
                }
            }
            report += cardSections
        }
        report += "\n## Key\n\n"
        for (index, contender) in contenders.enumerated() {
            report += "- \(Self.label(index)): \(contender.name)\n"
        }

        Attachment.record(report, named: "engine-comparison.md")
    }

    private static func draft(_ document: StudyDocument, with contender: Contender) async -> Run {
        let start = ContinuousClock.now
        let engine: any CardGenerating
        do {
            engine = try contender.makeEngine()
        } catch {
            return Run(cards: [], skippedSections: 0, seconds: 0, failure: failureCode(error))
        }
        do {
            let cards = try await CardGenerator.generateAI(
                from: document.lines.joined(separator: "\n"),
                document: document,
                engine: engine
            )
            return Run(cards: cards, skippedSections: engine.skippedSourceSections, seconds: seconds(since: start), failure: nil)
        } catch {
            return Run(cards: [], skippedSections: engine.skippedSourceSections, seconds: seconds(since: start), failure: failureCode(error))
        }
    }

    private static func failureCode(_ error: Error) -> String {
        (error as? CardGenerationError)?.code ?? String(describing: error)
    }

    /// The bundled sample always runs, so the report is never empty. Real documents go in
    /// `QuickStudyTests/ComparisonFixtures/` as .txt files; that folder is git-ignored
    /// because it holds the user's own notes.
    private static func documents() throws -> [StudyDocument] {
        let sample = StudyDocument(title: DemoData.set.title, lines: DemoData.set.lines)
        let fixtures = try (Bundle(for: BundleToken.self).urls(forResourcesWithExtension: "txt", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { url in
                let text = try String(contentsOf: url, encoding: .utf8)
                let lines = text.split(whereSeparator: \.isNewline).map(String.init)
                return StudyDocument(title: url.deletingPathExtension().lastPathComponent, lines: lines)
            }
        return [sample] + fixtures
    }

    private static func proTransactionJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            if case .verified = result { return result.jwsRepresentation }
        }
        return nil
    }

    private static func label(_ index: Int) -> String {
        String(UnicodeScalar(UInt8(ascii: "A") + UInt8(index)))
    }

    private static func seconds(since start: ContinuousClock.Instant) -> Double {
        let elapsed = ContinuousClock.now - start
        return Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
    }
}

private final class BundleToken {}

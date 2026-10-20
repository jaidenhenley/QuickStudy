//
//  PrivateCloudCardGenerationEngine.swift
//  QuickStudy
//

#if canImport(FoundationModels)
import Foundation
import FoundationModels

/// Built only by `PrivateCloud.makeEngine`, which owns the iOS 27 check.
@available(iOS 27, *)
struct PrivateCloudCardGenerationEngine: CardGenerating {
    let countsAgainstAllowance = true
    var sourceChunkLimit: Int? { Self.chunkLength }
    var skippedSourceSections: Int { skipped.count }
    let expectedSeconds: Double = 10
    let provenance = GenerationProvenance(engine: .privateCloud, model: "Apple Intelligence")
    var progress: GenerationProgress?
    let skipped = SkippedSectionCounter()
    private let model = PrivateCloudComputeLanguageModel()

    // Fixed rather than read from `contextSize`, which is async and this engine is built
    // synchronously. The core halves any chunk that still overflows.
    private static let chunkLength = 6000
    private static let topicSourceLength = 12_000

    func generateCards(from text: String) async throws -> [AIFlashcard] {
        try checkReady()
        return try await mappingErrors { try await core.cards(from: text) }
    }

    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard] {
        try checkReady()
        return try await mappingErrors { try await core.topicCards(from: text, topic: topic, count: count) }
    }

    private var core: CardDraftingCore {
        CardDraftingCore(
            chunkLength: Self.chunkLength,
            topicSourceLength: Self.topicSourceLength,
            progress: progress,
            skipped: skipped
        ) { [model] in LanguageModelSession(model: model, instructions: $0) }
    }

    private func checkReady() throws {
        guard model.isAvailable else { throw CardGenerationError.privateCloudUnavailable }
        let quota = model.quotaUsage
        if quota.isLimitReached { throw CardGenerationError.privateCloudQuotaReached(resetsAt: quota.resetDate) }
    }

    private func mappingErrors<T>(_ work: () async throws -> T) async throws -> T {
        do {
            return try await work()
        } catch let error as PrivateCloudComputeLanguageModel.Error {
            throw Self.mapped(error)
        }
    }

    private static func mapped(_ error: PrivateCloudComputeLanguageModel.Error) -> CardGenerationError {
        switch error {
        case .networkFailure: return .privateCloudNetworkFailure
        case .quotaLimitReached(let limit): return .privateCloudQuotaReached(resetsAt: limit.resetDate)
        case .serviceUnavailable: return .privateCloudUnavailable
        @unknown default: return .privateCloudUnavailable
        }
    }
}
#endif

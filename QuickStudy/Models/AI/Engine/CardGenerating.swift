//
//  CardGenerating.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 3/20/26.
//

import Foundation

protocol CardGenerating {
    var countsAgainstAllowance: Bool { get }
    /// Length an engine splits the source at, or nil when it reads the whole document in
    /// one pass. Drives the truncation notice on the drafts screen.
    var sourceChunkLimit: Int? { get }
    /// Measured typical duration, used by the drafting screen when an engine has no
    /// finer-grained progress to report.
    var expectedSeconds: Double { get }
    var provenance: GenerationProvenance { get }
    func generateCards(from text: String) async throws -> [AIFlashcard]
    func generateCards(from text: String, topic: String, count: Int) async throws -> [AIFlashcard]
}

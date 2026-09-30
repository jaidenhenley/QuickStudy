//
//  GenerationProvenance.swift
//  QuickStudy
//

import Foundation

/// Which engine actually drafted a set. Recorded from the engine that succeeded, not the
/// one first chosen — a refused cloud request falls back to this iPhone.
nonisolated struct GenerationProvenance: Codable, Hashable {
    enum Engine: String, Codable {
        case onDevice
        case cloud
        case externalAPI
    }

    let engine: Engine
    let model: String?
}

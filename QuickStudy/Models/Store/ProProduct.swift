//
//  ProProduct.swift
//  QuickStudy
//

import Foundation

enum ProProduct: String, CaseIterable {
    case monthly = "com.henley.jaiden.QuickStudy.pro.monthly"
    case yearly = "com.henley.jaiden.QuickStudy.pro.yearly"

    static let identifiers = allCases.map(\.rawValue)
    static let hostedMonthlyLimit = 150
    /// Must match the server's GENERATION_UNIT_CHARS: longer documents count as one
    /// generation per this many characters.
    static let generationUnitCharacters = 12_000
}

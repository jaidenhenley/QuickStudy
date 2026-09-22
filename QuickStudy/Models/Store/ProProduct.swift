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
}

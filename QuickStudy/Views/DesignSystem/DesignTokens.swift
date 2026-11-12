//
//  DesignTokens.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import CoreGraphics

enum AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 12
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppLayout {
    // Just wider than the iPhone Duo's unfolded portrait screen (669 pt), so only
    // landscape and wider windows are capped; every portrait layout is unchanged.
    static let readableWidth: CGFloat = 680
}

//
//  LayoutMetrics.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
    Swift.max(minValue, Swift.min(value, maxValue))
}

struct LayoutMetrics {
    let availableWidth: CGFloat

    // Use a single breakpoint to decide stacked vs. split layouts.
    let isStacked: Bool
    let spacing: CGFloat
    let padding: CGFloat
    let leftColumnWidth: CGFloat
    let rightColumnWidth: CGFloat

    init(availableWidth: CGFloat) {
        self.availableWidth = availableWidth
        isStacked = availableWidth < 700
        spacing = clamp(availableWidth * 0.03, min: 16, max: 28)
        padding = clamp(availableWidth * 0.03, min: 16, max: 28)
        leftColumnWidth = clamp(availableWidth * 0.52, min: 360, max: 520)
        rightColumnWidth = clamp(availableWidth - leftColumnWidth - spacing, min: 320, max: 560)
    }
}

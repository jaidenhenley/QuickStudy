//
//  PageDots.swift
//  QuickStudy
//

import SwiftUI

struct PageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.appPrimary : Theme.track)
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(current + 1) of \(count)")
        .appAnimation(Motion.snappy, value: current)
    }
}

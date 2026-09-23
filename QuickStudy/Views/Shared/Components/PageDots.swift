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
                    .fill(index == current ? Color.appPrimary : Color.secondary.opacity(0.3))
                    .frame(width: index == current ? 18 : 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: current)
    }
}

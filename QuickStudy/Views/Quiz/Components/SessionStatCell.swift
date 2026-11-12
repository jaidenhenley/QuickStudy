//
//  SessionStatCell.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionStatCell: View {
    let target: Int
    var isPercent = false
    let label: LocalizedStringResource
    let spokenLabel: LocalizedStringResource

    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 2) {
            Text(isPercent ? (Double(shown) / 100).formatted(.percent) : shown.formatted())
                .font(.title2)
                .fontWeight(.bold)
                .appNumericTransition(value: Double(shown))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spokenLabel))
        .accessibilityValue(isPercent ? (Double(target) / 100).formatted(.percent) : target.formatted())
        .onAppear {
            withAnimation(reduceMotion ? Motion.crossfade : Motion.countUp) {
                shown = target
            }
        }
    }
}

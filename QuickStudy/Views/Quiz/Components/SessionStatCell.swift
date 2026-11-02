//
//  SessionStatCell.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct SessionStatCell: View {
    let target: Int
    var suffix: String = ""
    let label: String

    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 2) {
            Text("\(shown)\(suffix)")
                .font(.title2)
                .fontWeight(.bold)
                .appNumericTransition(value: Double(shown))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label.capitalized)
        .accessibilityValue(suffix == "%" ? "\(target) percent" : "\(target)")
        .onAppear {
            withAnimation(reduceMotion ? Motion.crossfade : Motion.countUp) {
                shown = target
            }
        }
    }
}

//
//  ResultCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct ResultCard: View {
    enum Emphasis {
        case pop
        case shake
    }

    let label: String
    let text: String
    let tint: Color
    let symbol: String
    let emphasis: Emphasis?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playsEntrance = false

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .tracking(0.5)
                    .foregroundStyle(tint)
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Spacer()
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg, tint: tint.opacity(0.18))
        .phaseAnimator([1.0, 1.04], trigger: playsEntrance && emphasis == .pop) { content, scale in
            content.scaleEffect(scale)
        } animation: { scale in
            scale > 1 ? Motion.snappy : Motion.emphasized
        }
        .keyframeAnimator(initialValue: CGFloat.zero, trigger: playsEntrance && emphasis == .shake) { content, offset in
            content.offset(x: offset)
        } keyframes: { _ in
            KeyframeTrack {
                CubicKeyframe(6, duration: 0.05)
                CubicKeyframe(-6, duration: 0.06)
                CubicKeyframe(6, duration: 0.06)
                CubicKeyframe(-6, duration: 0.06)
                CubicKeyframe(6, duration: 0.06)
                CubicKeyframe(-6, duration: 0.06)
                CubicKeyframe(0, duration: 0.05)
            }
        }
        .accessibilityElement(children: .combine)
        // The card is inserted in the same update that reveals the answer, so no model value
        // changes after it exists; appearing is the only event left to key the entrance on.
        .onAppear { playsEntrance = !reduceMotion }
    }
}

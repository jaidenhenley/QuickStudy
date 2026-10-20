//
//  SourcePageView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

/// One page of the source document, with the lines a card came from highlighted.
struct SourcePageView: View {
    let lines: [String]
    let highlighted: ClosedRange<Int>?
    let lineOffset: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(lines.indices, id: \.self) { index in
                let absolute = index + lineOffset
                let isHighlighted = highlighted?.contains(absolute) ?? false

                Text(lines[index])
                    .font(.callout)
                    .foregroundStyle(isHighlighted ? Theme.textPrimary : .secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(absolute)
                    .anchorPreference(key: HighlightedLineBounds.self, value: .bounds) { anchor in
                        isHighlighted ? [anchor] : []
                    }
            }
        }
        .scrollTargetLayout()
        // One shape behind the whole range: a fill per line left every line but one bare,
        // and padding the highlighted lines reflowed their text on every card change.
        .backgroundPreferenceValue(HighlightedLineBounds.self) { anchors in
            GeometryReader { proxy in
                let rects = anchors.map { proxy[$0] }
                if let first = rects.first {
                    let bounds = rects.dropFirst().reduce(first) { $0.union($1) }
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(Color.appPrimary.opacity(0.15))
                        .frame(width: bounds.width + Spacing.sm * 2, height: bounds.height + Spacing.xs * 2)
                        .offset(x: bounds.minX - Spacing.sm, y: bounds.minY - Spacing.xs)
                }
            }
        }
    }
}

private struct HighlightedLineBounds: PreferenceKey {
    static var defaultValue: [Anchor<CGRect>] { [] }

    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) {
        value.append(contentsOf: nextValue())
    }
}

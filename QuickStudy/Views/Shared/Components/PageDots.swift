//
//  PageDots.swift
//  QuickStudy
//

import SwiftUI

struct PageDots: View {
    let count: Int
    let current: Int

    /// A long draft has one page per card; past this many dots the row is wider than the
    /// card and drags the whole card's content off both edges, so only a window is drawn.
    private static let maxVisible = 9

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(visibleRange, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.appPrimary : Theme.track)
                    .frame(width: index == current ? 18 : dotSize(index), height: dotSize(index))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page")
        .accessibilityValue("\(current + 1) of \(count)")
        .appAnimation(Motion.snappy, value: current)
    }

    private var visibleRange: Range<Int> {
        guard count > Self.maxVisible else { return 0..<count }
        let start = min(max(current - Self.maxVisible / 2, 0), count - Self.maxVisible)
        return start..<(start + Self.maxVisible)
    }

    /// The end dots shrink when more pages lie beyond them, the same cue the system pager uses.
    private func dotSize(_ index: Int) -> CGFloat {
        let range = visibleRange
        let hasMoreBefore = range.lowerBound > 0 && index == range.lowerBound
        let hasMoreAfter = range.upperBound < count && index == range.upperBound - 1
        return hasMoreBefore || hasMoreAfter ? 4 : 6
    }
}

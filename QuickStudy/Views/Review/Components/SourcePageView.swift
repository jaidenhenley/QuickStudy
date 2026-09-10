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
                    .padding(.horizontal, isHighlighted ? Spacing.sm : 0)
                    .padding(.vertical, isHighlighted ? 2 : 0)
                    .background(
                        isHighlighted ? Color.appPrimary.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: AppRadius.sm)
                    )
            }
        }
    }
}

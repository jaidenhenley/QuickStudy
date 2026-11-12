//
//  DraftingProgressHeader.swift
//  QuickStudy
//

import SwiftUI

struct DraftingProgressHeader: View {
    let report: DraftingReport

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(report.headline)
                    .font(.headline)
                    .contentTransition(.numericText())
                if let detail = report.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            Group {
                if let fraction = report.fraction {
                    ProgressView(value: fraction)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }
            }
            .tint(report.phase == .ready ? Theme.success : Theme.primary)
            .accessibilityHidden(true)
        }
        .padding(Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appGlassCard(cornerRadius: AppRadius.xl)
    }
}

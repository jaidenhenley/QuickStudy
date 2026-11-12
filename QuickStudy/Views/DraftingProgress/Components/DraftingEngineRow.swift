//
//  DraftingEngineRow.swift
//  QuickStudy
//

import SwiftUI

struct DraftingEngineRow: View {
    let engine: GenerationProvenance.Engine
    let sourceSummary: String?

    @ScaledMetric(relativeTo: .body) private var iconSize = 36.0

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: engine.symbolName)
                .font(.body)
                .foregroundStyle(Theme.aiAccentText)
                .frame(width: iconSize, height: iconSize)
                .background(Color.appAIAccent.opacity(0.15), in: .rect(cornerRadius: AppRadius.sm))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(engine.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                if let sourceSummary {
                    Text(sourceSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
        .accessibilityElement(children: .combine)
        .appAnimation(Motion.standard, value: engine)
    }
}

//
//  WhySourceCard.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct WhySourceCard: View {
    let explanation: String
    let source: CardSource?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(Color.appPrimary)
                Text("Why")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let source {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "link")
                    Text(source.longLabel)
                }
                .font(.caption)
                .foregroundStyle(Color.appPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .appGlassCard(cornerRadius: AppRadius.lg)
    }
}

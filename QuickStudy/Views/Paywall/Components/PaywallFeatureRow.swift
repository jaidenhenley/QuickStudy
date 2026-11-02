//
//  PaywallFeatureRow.swift
//  QuickStudy
//

import SwiftUI

struct PaywallFeatureRow: View {
    let symbol: String
    let text: String

    @ScaledMetric(relativeTo: .headline) private var iconWidth = 26.0

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.appPrimary)
                .frame(width: iconWidth)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

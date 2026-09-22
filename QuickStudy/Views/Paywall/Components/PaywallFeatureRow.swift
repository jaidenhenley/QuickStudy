//
//  PaywallFeatureRow.swift
//  QuickStudy
//

import SwiftUI

struct PaywallFeatureRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.headline)
                .foregroundStyle(.appPrimary)
                .frame(width: 26)
            Text(text)
                .font(.callout)
            Spacer(minLength: 0)
        }
    }
}

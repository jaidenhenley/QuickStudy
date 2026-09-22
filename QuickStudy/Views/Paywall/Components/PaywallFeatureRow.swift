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
                .frame(width: 28)
            Text(text)
                .font(.body)
            Spacer(minLength: 0)
        }
    }
}

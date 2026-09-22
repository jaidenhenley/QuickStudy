//
//  PaywallHeaderView.swift
//  QuickStudy
//

import SwiftUI

struct PaywallHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.appAIAccent)

            Text("QuickStudy Pro")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: Spacing.md) {
                PaywallFeatureRow(symbol: "brain", text: "Better cards, generated in the cloud")
                PaywallFeatureRow(symbol: "iphone", text: "Works on every iPhone")
                PaywallFeatureRow(symbol: "doc.text", text: "Whole documents, not chunks")
                PaywallFeatureRow(symbol: "infinity", text: "\(ProProduct.hostedMonthlyLimit) generations a month")
            }
            .padding(.top, Spacing.xs)

            Text("Pro sends your scanned text to QuickStudy's server to generate cards. It isn't stored.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        // Without this the store view centres short marketing content, leaving a gap under the close button.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, Spacing.lg)
    }
}

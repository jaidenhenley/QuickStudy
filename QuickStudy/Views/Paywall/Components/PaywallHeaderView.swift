//
//  PaywallHeaderView.swift
//  QuickStudy
//

import SwiftUI

struct PaywallHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(.appAIAccent)

            Text("QuickStudy Pro")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: Spacing.md) {
                PaywallFeatureRow(symbol: "brain", text: "Better cards, generated in the cloud")
                PaywallFeatureRow(symbol: "iphone", text: "Works on every iPhone")
                PaywallFeatureRow(symbol: "doc.text", text: "Whole documents, not 1,200-character chunks")
                PaywallFeatureRow(symbol: "infinity", text: "\(ProProduct.hostedMonthlyLimit) generations a month · no cap on this iPhone")
            }

            Text("Pro sends your scanned text to QuickStudy's server to generate cards. It isn't stored. Free generation stays on this iPhone.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
    }
}

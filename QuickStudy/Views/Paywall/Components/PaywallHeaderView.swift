//
//  PaywallHeaderView.swift
//  QuickStudy
//

import SwiftUI

struct PaywallHeaderView: View {
    let surface: PaywallSurface?

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.appAIAccent)
                .symbolEffect(.bounce, value: appeared)
                .appStagedReveal(0, shown: appeared)

            Text("QuickStudy Pro")
                .font(.title)
                .fontWeight(.bold)
                .appStagedReveal(1, shown: appeared)

            if surface == .exhausted {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Your free generations for this month are used up.")
                        .font(.body)
                    Text("They reset on \(GenerationAllowance.resetDate().formatted(.dateTime.month(.wide).day())).")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.sm)
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(Array([
                    (symbol: "brain", text: "Better cards, generated in the cloud"),
                    (symbol: "iphone", text: "Works on every iPhone"),
                    (symbol: "doc.text", text: "Whole documents, not chunks"),
                    (symbol: "sparkles", text: "\(ProProduct.hostedMonthlyLimit) generations a month")
                ].enumerated()), id: \.offset) { index, item in
                    PaywallFeatureRow(symbol: item.symbol, text: item.text)
                        .appStagedReveal(2 + index, shown: appeared)
                }
            }
            .padding(.top, Spacing.xs)

            Text("Pro sends your scanned text to QuickStudy's server to generate cards. It isn't stored.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            appeared = true
        }
    }
}

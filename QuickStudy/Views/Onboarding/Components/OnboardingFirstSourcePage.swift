//
//  OnboardingFirstSourcePage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingFirstSourcePage: View {
    let onChoose: (OnboardingViewModel.Choice) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Let's make your first set")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Pick how you want to start. You can always add more later.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button { onChoose(.demo) } label: {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("RECOMMENDED · 90 SECONDS")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(1)
                        .opacity(0.85)
                    Text("Try a demo set")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("4 sample sets. Feel the loop before you add your own.")
                        .font(.subheadline)
                        .opacity(0.9)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.xl, tint: Theme.primary)
            }
            .buttonStyle(.plain)

            Text("Or start with your own")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            GlassEffectContainer {
                VStack(spacing: Spacing.md) {
                    OnboardingSourceRow(symbol: "camera", title: "Scan a page", detail: "Photo of notes or textbook") {
                        onChoose(.source(.scan))
                    }
                    OnboardingSourceRow(symbol: "doc.text", title: "Drop in a PDF", detail: "Lecture slides, readings, handouts") {
                        onChoose(.source(.pdf))
                    }
                    OnboardingSourceRow(symbol: "text.alignleft", title: "Paste text", detail: "Notes, lecture transcript, anything") {
                        onChoose(.source(.paste))
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}

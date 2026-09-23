//
//  OnboardingHowItWorksPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingHowItWorksPage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("How it works")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Three steps. Under a minute.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.lg) {
                OnboardingStepRow(
                    number: 1,
                    title: "Capture your source",
                    detail: "Photo, PDF, or paste. Anything with text works."
                )
                OnboardingStepRow(
                    number: 2,
                    title: "We draft your cards",
                    detail: "AI reads it and writes Q&A. Edit anything."
                )
                OnboardingStepRow(
                    number: 3,
                    title: "Study smart, daily",
                    detail: "Spaced repetition surfaces what you need next."
                )
            }
            .padding(.top, Spacing.sm)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .controlSize(.large)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}

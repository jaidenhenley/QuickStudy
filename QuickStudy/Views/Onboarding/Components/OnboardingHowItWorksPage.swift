//
//  OnboardingHowItWorksPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingHowItWorksPage: View {
    let focus: AccessibilityFocusState<OnboardingViewModel.Page?>.Binding
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("How it works")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused(focus, equals: .howItWorks)
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
                        .appStagedReveal(0, shown: appeared)

                        OnboardingStepRow(
                            number: 2,
                            title: "We draft your cards",
                            detail: "AI reads it and writes Q&A. Edit anything."
                        )
                        .appStagedReveal(1, shown: appeared)

                        OnboardingStepRow(
                            number: 3,
                            title: "Study smart, daily",
                            detail: "Spaced repetition surfaces what you need next."
                        )
                        .appStagedReveal(2, shown: appeared)
                    }
                    .padding(.top, Spacing.sm)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primaryFill)
            .controlSize(.large)
            .appStagedReveal(3, shown: appeared)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .onAppear {
            appeared = true
        }
    }
}

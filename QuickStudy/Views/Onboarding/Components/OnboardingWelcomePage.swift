//
//  OnboardingWelcomePage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingWelcomePage: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(Color.appPrimary.opacity(0.25))
                    .frame(width: 120, height: 84)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -16, y: 12)
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(Color.appPrimary)
                    .frame(width: 120, height: 84)
                    .overlay {
                        Image(systemName: "sparkles")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color.appPrimary.opacity(0.35), radius: 16, y: 8)
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                Text("Notes in.\nFlashcards out.")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text("Snap a page, drop a PDF, paste text. QuickStudy drafts cards in seconds.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .controlSize(.large)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}

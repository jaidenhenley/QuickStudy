//
//  OnboardingWelcomePage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingWelcomePage: View {
    let focus: AccessibilityFocusState<OnboardingViewModel.Page?>.Binding
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Spacer(minLength: 0)

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
                                        .foregroundStyle(Theme.onPrimary)
                                        .appSymbolBounce(value: appeared)
                                }
                                .shadow(color: Color.appPrimary.opacity(0.35), radius: 16, y: 8)
                        }
                        .accessibilityHidden(true)
                        .appStagedReveal(0, shown: appeared)

                        Spacer(minLength: 0)

                        VStack(spacing: Spacing.md) {
                            Text("Notes in.\nFlashcards out.")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused(focus, equals: .welcome)
                            Text("Snap a page, drop a PDF, paste text. QuickStudy drafts cards in seconds.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primaryFill)
            .controlSize(.large)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .onAppear {
            appeared = true
        }
    }
}

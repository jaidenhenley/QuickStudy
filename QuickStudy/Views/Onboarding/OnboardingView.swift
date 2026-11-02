//
//  OnboardingView.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingView: View {
    @Environment(OnboardingViewModel.self) private var onboarding
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState private var focusedPage: OnboardingViewModel.Page?

    var body: some View {
        @Bindable var onboarding = onboarding

        VStack(spacing: Spacing.base) {
            Button {
                onboarding.goBack()
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.base)
            .opacity(onboarding.canGoBack ? 1 : 0)
            .disabled(!onboarding.canGoBack)
            .accessibilityHidden(!onboarding.canGoBack)

            TabView(selection: $onboarding.current) {
                ForEach(onboarding.pages, id: \.self) { page in
                    Group {
                        switch page {
                        case .welcome:
                            OnboardingWelcomePage(focus: $focusedPage) { onboarding.advance() }
                        case .howItWorks:
                            OnboardingHowItWorksPage(focus: $focusedPage) { onboarding.advance() }
                        case .aiIntro:
                            OnboardingAIIntroPage(setup: onboarding.draftingSetup, focus: $focusedPage) { onboarding.advance() }
                        case .camera:
                            OnboardingCameraPage(
                                focus: $focusedPage,
                                onAllow: { Task { await onboarding.requestCameraAccess() } },
                                onLater: { onboarding.advance() }
                            )
                        case .firstSource:
                            OnboardingFirstSourcePage(focus: $focusedPage) { choice in
                                analytics.record(.onboardingCompleted)
                                onboarding.choose(choice)
                                dismiss()
                            }
                        }
                    }
                    .accessibilityHidden(page != onboarding.current)
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .appAnimation(Motion.standard, value: onboarding.current)

            PageDots(count: onboarding.pages.count, current: onboarding.currentIndex)
                .padding(.bottom, Spacing.sm)
        }
        .background(BackgroundView())
        .onAppear { analytics.record(.onboardingStarted) }
        .onChange(of: onboarding.current) { _, page in
            focusedPage = page
        }
    }
}

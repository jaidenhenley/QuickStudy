//
//  OnboardingView.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingView: View {
    @Environment(OnboardingViewModel.self) private var onboarding
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var onboarding = onboarding

        VStack(spacing: Spacing.base) {
            TabView(selection: $onboarding.current) {
                ForEach(onboarding.pages, id: \.self) { page in
                    Group {
                        switch page {
                        case .welcome:
                            OnboardingWelcomePage { onboarding.advance() }
                        case .howItWorks:
                            OnboardingHowItWorksPage { onboarding.advance() }
                        case .aiIntro:
                            OnboardingAIIntroPage(hasOnDeviceModel: onboarding.hasOnDeviceModel) { onboarding.advance() }
                        case .camera:
                            OnboardingCameraPage(
                                onAllow: { Task { await onboarding.requestCameraAccess() } },
                                onLater: { onboarding.advance() }
                            )
                        case .firstSource:
                            OnboardingFirstSourcePage { choice in
                                analytics.record(.onboardingCompleted)
                                onboarding.choose(choice)
                                dismiss()
                            }
                        }
                    }
                    .tag(page)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: onboarding.current)

            PageDots(count: onboarding.pages.count, current: onboarding.currentIndex)
                .padding(.bottom, Spacing.sm)
        }
        .background(BackgroundView())
        .onAppear { analytics.record(.onboardingStarted) }
    }
}

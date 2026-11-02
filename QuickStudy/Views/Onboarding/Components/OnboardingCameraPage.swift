//
//  OnboardingCameraPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingCameraPage: View {
    let focus: AccessibilityFocusState<OnboardingViewModel.Page?>.Binding
    let onAllow: () -> Void
    let onLater: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        Spacer(minLength: 0)

                        Image(systemName: "camera")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.onPrimary)
                            .frame(width: 80, height: 80)
                            .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: AppRadius.xl))
                            .shadow(color: Color.appPrimary.opacity(0.35), radius: 16, y: 8)
                            .appSymbolBounce(value: appeared)
                            .accessibilityHidden(true)
                            .appStagedReveal(0, shown: appeared)

                        VStack(spacing: Spacing.sm) {
                            Text("Snap your notes")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityFocused(focus, equals: .camera)
                            Text("We'll ask for camera access next. Photos are read on this iPhone; the text from them helps draft your cards.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            VStack(spacing: Spacing.md) {
                Button(action: onAllow) {
                    Text("Allow camera access")
                        .frame(maxWidth: .infinity)
                }
                .appProminentButtonStyle(tint: Theme.primaryFill)
                .controlSize(.large)

                Button("Maybe later", action: onLater)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
        .onAppear {
            appeared = true
        }
    }
}

//
//  OnboardingAIIntroPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingAIIntroPage: View {
    let hasOnDeviceModel: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.title)
                .foregroundStyle(.appPrimary)
                .frame(width: 64, height: 64)
                .background(Color.appPrimary.opacity(0.12), in: Circle())

            VStack(spacing: Spacing.sm) {
                Text("Private by default")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                // Devices without Apple Intelligence can't draft on-device, so they must
                // never be told they can.
                Text(
                    hasOnDeviceModel
                        ? "QuickStudy turns notes into flashcards using Apple Intelligence — right on this iPhone."
                        : "This iPhone doesn't run Apple Intelligence, so QuickStudy drafts your cards in the cloud."
                )
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: Spacing.base) {
                if hasOnDeviceModel {
                    OnboardingFeatureRow(
                        symbol: "checkmark.shield",
                        title: "On this iPhone",
                        detail: "Your free generations run on-device and never leave it."
                    )
                    OnboardingFeatureRow(
                        symbol: "bolt",
                        title: "Works offline",
                        detail: "Generate and study on the plane, in the basement stacks."
                    )
                    OnboardingFeatureRow(
                        symbol: "sparkles",
                        title: "10 free generations a month",
                        detail: "Manual cards and every study mode are always unlimited."
                    )
                } else {
                    OnboardingFeatureRow(
                        symbol: "square.and.pencil",
                        title: "Manual cards, always free",
                        detail: "Type your own cards and study with every mode, unlimited."
                    )
                    OnboardingFeatureRow(
                        symbol: "icloud",
                        title: "More with Pro",
                        detail: "Cloud drafting on any iPhone, whenever you need it."
                    )
                }
            }
            .padding(.top, Spacing.sm)

            Text("Your first set is drafted in the cloud with our best model, so you see what QuickStudy can do. Your text isn't stored.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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

//
//  OnboardingAIIntroPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingAIIntroPage: View {
    let setup: DraftingSetup
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Four rows outgrow a small iPhone at large text sizes, so the content scrolls
            // and Continue stays pinned.
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.appPrimary)
                        .frame(width: 64, height: 64)
                        .background(Color.appPrimary.opacity(0.12), in: Circle())
                        .symbolEffect(.bounce, value: appeared)
                        .appStagedReveal(0, shown: appeared)

                    VStack(spacing: Spacing.sm) {
                        Text("Private by default")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .appStagedReveal(1, shown: appeared)

                    VStack(alignment: .leading, spacing: Spacing.base) {
                        ForEach(Array(features.enumerated()), id: \.offset) { index, item in
                            OnboardingFeatureRow(
                                symbol: item.symbol,
                                title: item.title,
                                detail: item.detail
                            )
                            .appStagedReveal(2 + index, shown: appeared)
                        }
                    }
                    .padding(.top, Spacing.sm)

                    Text(footnote)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xl)
            }
            .scrollBounceBehavior(.basedOnSize)

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .controlSize(.large)
            .appStagedReveal(2 + features.count, shown: appeared)
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            appeared = true
        }
    }

    private var subtitle: String {
        switch setup {
        case .privateCloud:
            return "QuickStudy drafts flashcards with Apple Intelligence, on this iPhone or in Apple's Private Cloud Compute."
        case .onDevice:
            return "QuickStudy turns notes into flashcards using Apple Intelligence, right on this iPhone."
        case .cloudOnly:
            return "This iPhone doesn't run Apple Intelligence, so QuickStudy drafts your cards in the cloud."
        }
    }

    private var features: [(symbol: String, title: String, detail: String)] {
        switch setup {
        case .privateCloud:
            return [
                (symbol: "lock.icloud", title: "Private Cloud Compute", detail: "Drafts run on Apple's servers with your permission. Your text isn't stored."),
                (symbol: "checkmark.shield", title: "Or keep it on this iPhone", detail: "Choose Not now and every draft stays on-device."),
                (symbol: "bolt", title: "Works offline", detail: "Study, quiz and edit offline anytime, anywhere."),
                (symbol: "sparkles", title: "10 free generations a month", detail: "Manual cards and every study mode are always unlimited.")
            ]
        case .onDevice:
            return [
                (symbol: "checkmark.shield", title: "On this iPhone", detail: "After your first set, generations run on-device and never leave it."),
                (symbol: "bolt", title: "Works offline", detail: "Study, quiz and edit offline anytime, anywhere."),
                (symbol: "sparkles", title: "10 free generations a month", detail: "Manual cards and every study mode are always unlimited.")
            ]
        case .cloudOnly:
            return [
                (symbol: "square.and.pencil", title: "Manual cards, always free", detail: "Type your own cards and study with every mode, unlimited."),
                (symbol: "icloud", title: "More with Pro", detail: "Cloud drafting on any iPhone, whenever you need it.")
            ]
        }
    }

    private var footnote: String {
        switch setup {
        case .privateCloud:
            return "You'll be asked before anything leaves this iPhone."
        case .onDevice, .cloudOnly:
            return "Your first set is drafted in the cloud with your permission, so you see what QuickStudy can do. Your text isn't stored."
        }
    }
}

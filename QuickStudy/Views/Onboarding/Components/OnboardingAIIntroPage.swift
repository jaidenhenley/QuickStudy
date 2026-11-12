//
//  OnboardingAIIntroPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingAIIntroPage: View {
    let setup: DraftingSetup
    let focus: AccessibilityFocusState<OnboardingViewModel.Page?>.Binding
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
                        .appSymbolBounce(value: appeared)
                        .accessibilityHidden(true)
                        .appStagedReveal(0, shown: appeared)

                    VStack(spacing: Spacing.sm) {
                        Text("Private by default")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused(focus, equals: .aiIntro)
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
            .appProminentButtonStyle(tint: Theme.primaryFill)
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
            return String(localized: "QuickStudy drafts flashcards with Apple Intelligence, on this iPhone or in Apple's Private Cloud Compute.")
        case .onDevice:
            return String(localized: "QuickStudy turns notes into flashcards using Apple Intelligence, right on this iPhone.")
        case .cloudOnly:
            return String(localized: "This iPhone doesn't run Apple Intelligence, so QuickStudy drafts your cards in the cloud.")
        }
    }

    private var features: [(symbol: String, title: String, detail: String)] {
        switch setup {
        case .privateCloud:
            return [
                (symbol: "lock.icloud", title: String(localized: "Private Cloud Compute"), detail: String(localized: "Drafts run on Apple's servers with your permission. Your text isn't stored.")),
                (symbol: "checkmark.shield", title: String(localized: "Or keep it on this iPhone"), detail: String(localized: "Choose Not now and every draft stays on-device.")),
                (symbol: "bolt", title: String(localized: "Works offline"), detail: String(localized: "Study, quiz and edit offline anytime, anywhere.")),
                (symbol: "sparkles", title: String(localized: "10 free generations a month"), detail: String(localized: "Manual cards and every study mode are always unlimited."))
            ]
        case .onDevice:
            return [
                (symbol: "checkmark.shield", title: String(localized: "On this iPhone"), detail: String(localized: "After your first set, generations run on-device and never leave it.")),
                (symbol: "bolt", title: String(localized: "Works offline"), detail: String(localized: "Study, quiz and edit offline anytime, anywhere.")),
                (symbol: "sparkles", title: String(localized: "10 free generations a month"), detail: String(localized: "Manual cards and every study mode are always unlimited."))
            ]
        case .cloudOnly:
            return [
                (symbol: "square.and.pencil", title: String(localized: "Manual cards, always free"), detail: String(localized: "Type your own cards and study with every mode, unlimited.")),
                (symbol: "icloud", title: String(localized: "More with Pro"), detail: String(localized: "Cloud drafting on any iPhone, whenever you need it."))
            ]
        }
    }

    private var footnote: String {
        switch setup {
        case .privateCloud:
            return String(localized: "You'll be asked before anything leaves this iPhone.")
        case .onDevice, .cloudOnly:
            return String(localized: "Your first set is drafted in the cloud with your permission, so you see what QuickStudy can do. Anthropic, which drafts it, deletes your text within 30 days.")
        }
    }
}

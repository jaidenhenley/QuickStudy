//
//  HostedConsentSheet.swift
//  QuickStudy
//

import SwiftUI

struct HostedConsentSheet: View {
    let setup: DraftingSetup
    let onAllow: () -> Void
    let onNotNow: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    Text("Draft this set in the cloud?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)

            Link("Privacy Policy", destination: LegalLinks.privacyPolicyURL)
                .font(.subheadline)
                .foregroundStyle(Theme.primary)
                .frame(minHeight: 44)

            Button {
                onAllow()
                dismiss()
            } label: {
                Text("Allow")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .appProminentButtonStyle(tint: Theme.primaryFill)

            Button {
                onNotNow()
                dismiss()
            } label: {
                Text("Not now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(.plain)
            .appGlassCard(cornerRadius: AppRadius.md)
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(500), .large])
        .presentationDragIndicator(.visible)
    }

    private var message: String {
        switch setup {
        case .privateCloud:
            return "Your document's text is drafted by Apple's Private Cloud Compute, or on QuickStudy's server with Anthropic's Claude. Apple and QuickStudy don't keep it, and Anthropic deletes it within 30 days. Choose Not now to keep every draft on this iPhone."
        case .onDevice:
            return "Your document's text is drafted on QuickStudy's server with Anthropic's Claude. QuickStudy doesn't keep it, and Anthropic deletes it within 30 days. Choose Not now to keep every draft on this iPhone."
        case .cloudOnly:
            return "This iPhone doesn't run Apple Intelligence, so your document's text is drafted on QuickStudy's server with Anthropic's Claude. QuickStudy doesn't keep it, and Anthropic deletes it within 30 days. Choose Not now to type your cards yourself."
        }
    }
}

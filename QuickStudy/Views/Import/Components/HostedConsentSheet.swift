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

    @ScaledMetric(relativeTo: .title) private var badgeSize = 64.0
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let hasOnDeviceModel = setup != .cloudOnly
        // Sized to the content: the medium detent rested the Privacy Policy link half
        // under the buttons, which reads as clipped rather than scrollable.
        let fittedHeight = contentHeight + 44 * 2 + Spacing.base * 2 + Spacing.lg * 3

        VStack(spacing: Spacing.base) {
            ScrollView {
                VStack(spacing: Spacing.base) {
                    Image(systemName: "icloud")
                        .font(.title)
                        .foregroundStyle(Theme.primary)
                        .frame(width: badgeSize, height: badgeSize)
                        .background(Theme.primary.opacity(0.14), in: Circle())
                        .accessibilityHidden(true)

                    Text(hasOnDeviceModel ? "Draft in the Cloud?" : "Draft This Set in the Cloud?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)

                    Text(hasOnDeviceModel
                         ? "Cloud drafting makes better cards. Your text is sent to Apple’s Private Cloud Compute or to QuickStudy’s server, which uses Anthropic’s Claude. Claude deletes it within 30 days. Not Now drafts on this iPhone."
                         : "This iPhone can’t draft cards on its own. Your text is sent to Apple’s Private Cloud Compute or to QuickStudy’s server, which uses Anthropic’s Claude. Claude deletes it within 30 days.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Link("Privacy Policy", destination: LegalLinks.privacyPolicyURL)
                        .font(.subheadline)
                        .foregroundStyle(Theme.primary)
                        .frame(minHeight: 44)
                }
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)

            Button {
                onAllow()
                dismiss()
            } label: {
                Text("Allow")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .appProminentButtonStyle(tint: Theme.primaryFill)
            .buttonBorderShape(.capsule)

            Button {
                onNotNow()
                dismiss()
            } label: {
                Text("Not Now")
                    .font(.headline)
                    .foregroundStyle(Theme.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [contentHeight == 0 ? .medium : .height(fittedHeight)])
        .presentationDragIndicator(.visible)
    }
}

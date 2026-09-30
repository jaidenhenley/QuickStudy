//
//  HostedConsentSheet.swift
//  QuickStudy
//

import SwiftUI

struct HostedConsentSheet: View {
    let onAllow: () -> Void
    let onNotNow: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            Text("Draft this set in the cloud?")
                .font(.title2)
                .fontWeight(.bold)

            Text("Your document's text is sent to QuickStudy's server and drafted by AI running on Cloudflare. Your text isn't stored after drafting. Later free sets are drafted on this iPhone.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Link("Privacy Policy", destination: LegalLinks.privacyPolicyURL)
                .font(.subheadline)
                .foregroundStyle(.blue)

            Spacer(minLength: 0)

            Button {
                onAllow()
                dismiss()
            } label: {
                Text("Allow")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)

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
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
    }
}

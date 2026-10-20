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

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            Text("Draft this set in the cloud?")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
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

    private var message: String {
        switch setup {
        case .privateCloud:
            return "Your document's text is drafted by Apple's Private Cloud Compute or QuickStudy's server. It isn't stored after drafting. Choose Not now to keep every draft on this iPhone."
        case .onDevice:
            return "Your document's text is drafted on QuickStudy's server. It isn't stored after drafting. Choose Not now to keep every draft on this iPhone."
        case .cloudOnly:
            return "This iPhone doesn't run Apple Intelligence, so your document's text is drafted on QuickStudy's server. It isn't stored after drafting. Choose Not now to type your cards yourself."
        }
    }
}

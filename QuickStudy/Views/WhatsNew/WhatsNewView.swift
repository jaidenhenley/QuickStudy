//
//  WhatsNewView.swift
//  QuickStudy
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(WhatsNewViewModel.self) private var whatsNew
    @Environment(StoreController.self) private var store
    @Environment(AISettings.self) private var aiSettings
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("VERSION \(whatsNew.note.version)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .tracking(1)
                        Text("What's New")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(whatsNew.note.headline)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .appStagedReveal(0, shown: appeared)

                    VStack(alignment: .leading, spacing: Spacing.base) {
                        ForEach(Array(whatsNew.note.features.enumerated()), id: \.element.id) { index, feature in
                            OnboardingFeatureRow(
                                symbol: feature.symbol,
                                title: feature.title,
                                detail: feature.detail
                            )
                            .appStagedReveal(1 + index, shown: appeared)
                        }
                    }

                    if whatsNew.showsProFeature, let proFeature = whatsNew.note.proFeature {
                        WhatsNewProCard(feature: proFeature) {
                            showPaywall = true
                        }
                        .appStagedReveal(1 + whatsNew.note.features.count, shown: appeared)
                        .appTransition(.opacity)
                    }

                    if whatsNew.showsCloudNotice, let cloudNotice = whatsNew.note.cloudNotice {
                        Text(cloudNotice)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .appStagedReveal(2 + whatsNew.note.features.count, shown: appeared)
                    }
                }
                .padding(Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .appProminentButtonStyle(tint: Theme.primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(BackgroundView())
        .presentationDragIndicator(.visible)
        .appAnimation(value: whatsNew.showsProFeature)
        .sheet(isPresented: $showPaywall) { PaywallView(surface: nil) }
        .onAppear {
            whatsNew.refresh(settings: aiSettings, store: store)
            appeared = true
        }
        .onChange(of: store.isPro) {
            whatsNew.refresh(settings: aiSettings, store: store)
        }
    }
}

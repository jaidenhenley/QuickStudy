//
//  PaywallView.swift
//  QuickStudy
//

import StoreKit
import SwiftUI

// Apple's standard EULA, used because QuickStudy has not published a custom one.
private let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
private let privacyPolicyURL = URL(string: "https://jaidenhenley.github.io/JaidenHenleyPort/quickstudy-privacy.html")!

struct PaywallView: View {
    let surface: PaywallSurface

    @Environment(StoreController.self) private var store
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseMessage: String?
    @State private var showPurchaseMessage = false

    var body: some View {
        // Presented as a sheet, the store view supplies its own close button.
        SubscriptionStoreView(productIDs: ProProduct.identifiers) {
            PaywallHeaderView()
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        // Required by App Store Guideline 3.1.2 — SubscriptionStoreView renders
        // these as visible, tappable links itself once destinations are set.
        .subscriptionStorePolicyDestination(url: termsOfUseURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: privacyPolicyURL, for: .privacyPolicy)
        .onInAppPurchaseStart { _ in
            analytics.record(.purchaseInitiated)
        }
        .onInAppPurchaseCompletion { _, result in
            switch result {
            case .success(.success):
                await store.refreshEntitlement()
                if store.isPro {
                    dismiss()
                } else {
                    present("The purchase went through but couldn't be verified. Try Restore Subscription.")
                }
            case .success(.pending):
                present("Your purchase needs approval before it can finish. You'll get Pro once it's approved.")
            case .success(.userCancelled):
                break
            case .failure(let error):
                present(error.localizedDescription)
            @unknown default:
                present("The purchase didn't complete. Try again.")
            }
        }
        .background(BackgroundView())
        .onAppear { analytics.record(.paywallShown(surface)) }
        .onDisappear {
            guard !store.isPro else { return }
            analytics.record(.paywallDismissed(surface))
        }
        .alert("Purchase didn't finish", isPresented: $showPurchaseMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseMessage ?? "Try again.")
        }
    }

    private func present(_ message: String) {
        purchaseMessage = message
        showPurchaseMessage = true
    }
}

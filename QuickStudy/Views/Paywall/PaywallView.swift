//
//  PaywallView.swift
//  QuickStudy
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    let surface: PaywallSurface

    @Environment(StoreController.self) private var store
    @Environment(AnalyticsRecorder.self) private var analytics
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseMessage: String?
    @State private var showPurchaseMessage = false
    @State private var showWelcome = false

    var body: some View {
        // Presented as a sheet, the store view supplies its own close button.
        SubscriptionStoreView(productIDs: ProProduct.identifiers) {
            PaywallHeaderView(surface: surface)
        }
        .subscriptionStoreControlStyle(.prominentPicker)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        // Required by App Store Guideline 3.1.2 — SubscriptionStoreView renders
        // these as visible, tappable links itself once destinations are set.
        .subscriptionStorePolicyDestination(url: LegalLinks.termsOfUseURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: LegalLinks.privacyPolicyURL, for: .privacyPolicy)
        .onInAppPurchaseStart { _ in
            analytics.record(.purchaseInitiated)
        }
        .onInAppPurchaseCompletion { _, result in
            switch result {
            case .success(.success):
                await store.refreshEntitlement()
                if store.isPro {
                    showWelcome = true
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
            if !store.isPro { analytics.record(.paywallDismissed(surface)) }
            // Restore Purchases syncs with the App Store but reports no completion to this view.
            Task { await store.refreshEntitlement() }
        }
        .alert("Purchase didn't finish", isPresented: $showPurchaseMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(purchaseMessage ?? "Try again.")
        }
        .alert("You're on QuickStudy Pro", isPresented: $showWelcome) {
            Button("Continue") { dismiss() }
        } message: {
            Text("You now have \(ProProduct.hostedMonthlyLimit) cloud generations a month.")
        }
    }

    private func present(_ message: String) {
        purchaseMessage = message
        showPurchaseMessage = true
    }
}

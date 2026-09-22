//
//  PaywallView.swift
//  QuickStudy
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(StoreController.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(productIDs: ProProduct.identifiers) {
                PaywallHeaderView()
            }
            .subscriptionStoreControlStyle(.prominentPicker)
            .storeButton(.visible, for: .restorePurchases)
            .onInAppPurchaseCompletion { _, result in
                guard case .success(.success(_)) = result else { return }
                await store.refreshEntitlement()
                if store.isPro { dismiss() }
            }
            .background(BackgroundView())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }
}

//
//  ContentView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/25/26.
//

import SwiftUI

struct ContentView: View {
    // Shared app state for the whole flow
    @State private var viewModel = StudyViewModel()
    @State private var appState = AppState()
    @State private var aiSettings = AISettings()
    @State private var todayViewModel = TodayViewModel()
    @State private var draftStore = DraftStore()
    @State private var sessionStore = SessionStore()
    @State private var networkMonitor = NetworkMonitor()
    @State private var store = StoreController()
    @State private var analytics = AnalyticsRecorder()
    @State private var onboarding: OnboardingViewModel?
    @State private var showOnboarding = false
    @State private var showOnboardingPaywall = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "house")
            }
            .tag(AppState.Tab.today)

            NavigationStack {
                LibraryView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(AppState.Tab.library)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(AppState.Tab.stats)
        }
        .environment(todayViewModel)
        .environment(draftStore)
        .environment(sessionStore)
        .environment(viewModel)
        .environment(appState)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                viewModel.flushPendingChanges()
                Task { await analytics.flush() }
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .environment(aiSettings)
        .environment(networkMonitor)
        .environment(store)
        .environment(analytics)
        .task {
            await store.refreshEntitlement()
            analytics.record(.deviceCapability(hasOnDeviceModel: AICapability.state(for: aiSettings) != .unsupportedDevice))
        }
        .onAppear {
            viewModel.aiSettings = aiSettings
            viewModel.store = store
            viewModel.analytics = analytics
            startOnboardingIfNeeded()
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: finishOnboarding) {
            if let onboarding {
                OnboardingView()
                    .environment(onboarding)
                    .environment(analytics)
            }
        }
        // Onboarding's paywall waits for the first set the user made themselves, so the
        // ask follows real value rather than landing before it.
        .onChange(of: viewModel.userSetCount) { old, new in
            guard new > old, OnboardingViewModel.isPaywallPending, !store.isPro else { return }
            OnboardingViewModel.setPaywallPending(false)
            showOnboardingPaywall = true
        }
        .sheet(isPresented: $showOnboardingPaywall) {
            PaywallView(surface: .onboarding)
                .environment(store)
                .environment(analytics)
        }
    }

    private func startOnboardingIfNeeded() {
        guard onboarding == nil, !OnboardingViewModel.hasCompleted else { return }
        // Anyone upgrading with sets already saved has been using the app; don't onboard them.
        guard viewModel.userSetCount == 0 else {
            OnboardingViewModel.markCompleted()
            return
        }
        onboarding = OnboardingViewModel(settings: aiSettings)
        showOnboarding = true
    }

    /// Runs once the cover is fully down — presenting the import sheet mid-dismissal
    /// would drop it.
    private func finishOnboarding() {
        guard let choice = onboarding?.choice else { return }
        if !store.isPro { OnboardingViewModel.setPaywallPending(true) }
        switch choice {
        case .demo:
            viewModel.demoModeEnabled = true
            appState.selectedTab = .today
        case .source(let source):
            appState.selectedTab = .library
            appState.pendingImportSource = source
        }
        onboarding = nil
    }
}

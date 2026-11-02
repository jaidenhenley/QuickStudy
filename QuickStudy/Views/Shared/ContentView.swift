//
//  ContentView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/25/26.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel: StudyViewModel
    @State private var appState = AppState()
    @State private var aiSettings: AISettings
    @State private var todayViewModel = TodayViewModel()
    @State private var draftStore = DraftStore()
    @State private var sessionStore = SessionStore()
    @State private var networkMonitor = NetworkMonitor()
    @State private var store: StoreController
    @State private var analytics: AnalyticsRecorder
    @State private var onboarding: OnboardingViewModel?
    @State private var presentations = RootPresentationQueue()
    @State private var whatsNew: WhatsNewViewModel?
    @Environment(\.scenePhase) private var scenePhase

    private let releaseTracker = ReleaseTracker()

    /// One instance of each, shared with the view model — a second `StoreController`
    /// would mean a second `Transaction.updates` listener and a second view of entitlement.
    init() {
        let aiSettings = AISettings()
        let analytics = AnalyticsRecorder()
        let store = StoreController(analytics: analytics)
        _aiSettings = State(initialValue: aiSettings)
        _analytics = State(initialValue: analytics)
        _store = State(initialValue: store)
        _viewModel = State(initialValue: StudyViewModel(aiSettings: aiSettings, store: store, analytics: analytics))
    }

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
            if phase == .active {
                // Catches a renewal, lapse, refund or restore that happened while away.
                Task { await store.refreshEntitlement() }
            } else {
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
            store.startObservingTransactions()
            await store.refreshEntitlement()
            analytics.record(.deviceCapability(hasOnDeviceModel: AICapability.state(for: aiSettings) != .unsupportedDevice))
        }
        .onAppear {
            presentLaunchSheetIfNeeded()
        }
        .fullScreenCover(
            isPresented: presentations.isPresenting(.onboarding, settle: RootPresentationQueue.sheetSettle),
            onDismiss: finishOnboarding
        ) {
            if let onboarding {
                OnboardingView()
                    .environment(onboarding)
                    .environment(analytics)
            }
        }
        // Onboarding's paywall waits for the first set the user made themselves, so the
        // ask follows real value rather than landing before it. The delay lets the sheet
        // that saved the set finish dismissing first.
        .onChange(of: viewModel.userSetCount) { old, new in
            guard new > old, OnboardingViewModel.isPaywallPending, !store.isPro else { return }
            presentations.enqueue(.onboardingPaywall, after: RootPresentationQueue.sheetSettle)
        }
        .sheet(isPresented: presentations.isPresenting(.onboardingPaywall, settle: RootPresentationQueue.sheetSettle)) {
            PaywallView(surface: .onboarding)
                .environment(store)
                .environment(analytics)
                .onAppear { OnboardingViewModel.setPaywallPending(false) }
        }
        .onChange(of: viewModel.isLibraryIssuePresented, initial: true) { _, isPresented in
            if isPresented { presentations.enqueue(.libraryIssue) }
        }
        .onChange(of: sessionStore.isLoadIssuePresented, initial: true) { _, isPresented in
            if isPresented { presentations.enqueue(.historyIssue) }
        }
        .onChange(of: draftStore.isLoadIssuePresented, initial: true) { _, isPresented in
            if isPresented { presentations.enqueue(.draftIssue) }
        }
        .alert(
            "Couldn't open your library",
            isPresented: presentations.isPresenting(.libraryIssue, settle: RootPresentationQueue.alertSettle) {
                viewModel.isLibraryIssuePresented = false
            }
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.libraryIssueMessage)
        }
        .alert(
            "Couldn't open your study history",
            isPresented: presentations.isPresenting(.historyIssue, settle: RootPresentationQueue.alertSettle) {
                sessionStore.isLoadIssuePresented = false
            }
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(sessionStore.loadIssueMessage)
        }
        .alert(
            "Couldn't open your draft",
            isPresented: presentations.isPresenting(.draftIssue, settle: RootPresentationQueue.alertSettle) {
                draftStore.isLoadIssuePresented = false
            }
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(draftStore.loadIssueMessage)
        }
        .sheet(
            isPresented: presentations.isPresenting(.whatsNew, settle: RootPresentationQueue.sheetSettle) {
                releaseTracker.markSeen()
            },
            onDismiss: { whatsNew = nil }
        ) {
            if let presented = whatsNew {
                WhatsNewView()
                    .environment(presented)
                    .environment(store)
                    .environment(aiSettings)
                    .environment(analytics)
            }
        }
    }

    private func presentLaunchSheetIfNeeded() {
        guard onboarding == nil, whatsNew == nil else { return }
        switch releaseTracker.launchSheet(
            hasUserSets: viewModel.userSetCount > 0,
            hasCompletedOnboarding: OnboardingViewModel.hasCompleted
        ) {
        case .onboarding:
            // Marked now, not on finish, so quitting mid-onboarding and making sets later
            // can't make this install look like an upgrader.
            releaseTracker.markSeen()
            onboarding = OnboardingViewModel(settings: aiSettings)
            presentations.enqueue(.onboarding)
        case .whatsNew(let note):
            // Upgraders have been using the app; they get release notes, not onboarding.
            OnboardingViewModel.markCompleted()
            whatsNew = WhatsNewViewModel(note: note)
            presentations.enqueue(.whatsNew)
        case nil:
            break
        }
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

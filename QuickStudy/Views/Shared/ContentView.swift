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
        }
    }
}

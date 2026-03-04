//
//  ContentView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/25/26.
//

import SwiftUI

struct ContentView: View {
    // Shared app state for the whole flow
    @StateObject private var viewModel = StudyViewModel()
    @StateObject private var appState = AppState()
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false

    @State private var splitSelection: SplitItem? = .home
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            BackgroundView()

            if horizontalSizeClass == .compact {
                TabView(selection: $appState.selectedTab) {
                    NavigationStack {
                        RootHomeView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(AppState.Tab.scan)

                    NavigationStack {
                        SavedSetsView()
                    }
                    .tabItem {
                        Label("Sets", systemImage: "square.grid.2x2")
                    }
                    .tag(AppState.Tab.savedSets)

                    NavigationStack {
                        QuizView()
                    }
                    .tabItem {
                        Label("Quiz", systemImage: "checklist")
                    }
                    .tag(AppState.Tab.quiz)
                }
                .tint(Theme.primary)
            } else {
                NavigationSplitView(columnVisibility: $appState.splitVisibility) {
                    List(selection: $splitSelection) {
                        Label("Home", systemImage: "house")
                            .tag(SplitItem.home)
                        Label("Sets", systemImage: "square.grid.2x2")
                            .tag(SplitItem.sets)
                        Label("Quiz", systemImage: "checklist")
                            .tag(SplitItem.quiz)
                    }
                    .navigationTitle("Browse")
                } detail: {
                    NavigationStack {
                        splitDetailView
                    }
                }
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 340)
            }
        }
        .foregroundStyle(Theme.textPrimary)
        .environmentObject(viewModel)
        .environmentObject(appState)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(
                onDismiss: {
                    didShowOnboarding = true
                    showOnboarding = false
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if !didShowOnboarding {
                showOnboarding = true
            }
        }
        .onChange(of: appState.selectedTab) { newValue, _ in
            if newValue == .quiz {
                appState.isQuickQuizEntry = false
            }
        }
        .onChange(of: splitSelection) { newValue, _ in
            if newValue == .quiz {
                appState.isQuickQuizEntry = false
            }
        }
    }
}

private extension ContentView {
    enum SplitItem: Hashable {
        case home
        case sets
        case quiz
    }

    @ViewBuilder
    var splitDetailView: some View {
        switch splitSelection ?? .home {
        case .home:
            IpadHomeScreen(dashboardViewModel: dashboardViewModel)
        case .sets:
            SavedSetsView()
                .navigationTitle("Saved Sets")
        case .quiz:
            QuizView()
                .navigationTitle("Quiz")
        }
    }

}

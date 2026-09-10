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
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false
    
    @State private var showOnboarding = false
    @State private var showTutorialOverlay = false
    @State private var currentTutorialStep: TutorialStep = .welcome
    
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
        .environment(viewModel)
        .environment(appState)
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { viewModel.flushPendingChanges() }
        }
        .foregroundStyle(Theme.textPrimary)
        .environment(aiSettings)
        .overlay {
            if showTutorialOverlay {
                TutorialOverlay(
                    step: currentTutorialStep,
                    onNext: advanceTutorial,
                    onSkip: {
                        showTutorialOverlay = false
                        didShowOnboarding = true
                    }
                )
                .id(currentTutorialStep)
                .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            WelcomeScreen(
                onStart: {
                    showOnboarding = false
                    startTutorial()
                },
                onSkip: {
                    showOnboarding = false
                    didShowOnboarding = true
                }
            )
        }
        .onAppear {
            viewModel.aiSettings = aiSettings
            if !didShowOnboarding {
                showOnboarding = true
            }
        }
        
    }
    
    private func startTutorial() {
        viewModel.demoModeEnabled = true
        currentTutorialStep = .viewDemoSets
        Task {
            // sleep only throws on cancellation, where showing the overlay is still correct
            try? await Task.sleep(for: .seconds(0.5))
            showTutorialOverlay = true
        }
    }
    
    private func advanceTutorial() {
        withAnimation {
            switch currentTutorialStep {
            case .welcome:
                currentTutorialStep = .viewDemoSets
            case .viewDemoSets:
                currentTutorialStep = .tapFirstSet
            case .tapFirstSet:
                currentTutorialStep = .viewFlashcards
            case .viewFlashcards:
                currentTutorialStep = .approveCard
            case .approveCard:
                currentTutorialStep = .openStudyMode
            case .openStudyMode:
                currentTutorialStep = .viewStudyList
            case .viewStudyList:
                currentTutorialStep = .startPractice
            case .startPractice:
                currentTutorialStep = .flipCard
            case .flipCard:
                currentTutorialStep = .goToQuiz
            case .goToQuiz:
                currentTutorialStep = .startQuiz
            case .startQuiz:
                currentTutorialStep = .complete
            case .complete:
                showTutorialOverlay = false
                didShowOnboarding = true
            }
        }
    }
}


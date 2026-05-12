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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false
    
    @State private var showOnboarding = false
    @State private var showTutorialOverlay = false
    @State private var currentTutorialStep: TutorialStep = .welcome
    
    var body: some View {
        ZStack {
            BackgroundView()
            
            
            if horizontalSizeClass == .compact {
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
                }
                .environment(todayViewModel)
                .environment(viewModel)
                .environment(appState)
            } else {
                
            }
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
                        viewModel.demoModeEnabled = false
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
                    viewModel.demoModeEnabled = false
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
                viewModel.demoModeEnabled = false
                didShowOnboarding = true
            }
        }
    }
    
    private func handleStepChange(_ step: TutorialStep) {
        // Auto-advance after showing informational steps
        switch step {
        case .viewDemoSets:
            // Give user 8 seconds to see the demo sets
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if self.currentTutorialStep == .viewDemoSets {
                    self.advanceTutorial()
                }
            }
        case .viewFlashcards:
            // Give user 10 seconds to see the flashcards view
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if self.currentTutorialStep == .viewFlashcards {
                    self.advanceTutorial()
                }
            }
        case .approveCard:
            // Scroll to flashcards section when this step appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    self.appState.scrollToFlashcards = true
                }
            }
        case .viewStudyList:
            // Give user 6 seconds to see the study list
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                if self.currentTutorialStep == .viewStudyList {
                    self.advanceTutorial()
                }
            }
        case .flipCard:
            // Give user 8 seconds to try flipping the card
            DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                if self.currentTutorialStep == .flipCard {
                    self.advanceTutorial()
                }
            }
        case .startQuiz:
            // Give user 6 seconds to see the quiz
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                if self.currentTutorialStep == .startQuiz {
                    self.advanceTutorial()
                }
            }
        default:
            break
        }
    }
}


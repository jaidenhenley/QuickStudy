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
    @State private var showTutorialOverlay = false
    @State private var currentTutorialStep: TutorialStep = .welcome

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
                    viewModel.demoModeEnabled = true
                    // Start at viewDemoSets (step 1 of tutorial overlay)
                    currentTutorialStep = .viewDemoSets
                    // Delay showing overlay so user sees the app first
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showTutorialOverlay = true
                    }
                },
                onSkip: {
                    showOnboarding = false
                    viewModel.demoModeEnabled = false
                    didShowOnboarding = true
                }
            )
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
        .onChange(of: appState.setDetailViewAppeared) { _, _ in
            if showTutorialOverlay {
                print("📚 Set detail view appeared - current step: \(currentTutorialStep)")
                // When user taps a set, we advance from tapFirstSet to viewFlashcards
                if currentTutorialStep == .tapFirstSet {
                    print("   → Advancing from tapFirstSet to viewFlashcards")
                    advanceTutorial()
                }
            }
        }
        .onChange(of: appState.studyViewAppeared) { _, _ in
            if showTutorialOverlay && currentTutorialStep == .openStudyMode {
                print("📚 Study view appeared - advancing from openStudyMode to viewStudyList")
                advanceTutorial()
            }
        }
        .onChange(of: appState.practiceViewAppeared) { _, _ in
            if showTutorialOverlay && currentTutorialStep == .startPractice {
                print("🎴 Practice view appeared - advancing from startPractice to flipCard")
                advanceTutorial()
            }
        }
        .onChange(of: appState.quizViewAppeared) { _, _ in
            if showTutorialOverlay && currentTutorialStep == .goToQuiz {
                print("📝 Quiz view appeared - advancing from goToQuiz to startQuiz")
                advanceTutorial()
            }
        }
        .onChange(of: currentTutorialStep) { _, newStep in
            handleStepChange(newStep)
        }
        .onChange(of: viewModel.flashcards) { oldCards, newCards in
            // Detect when a card gets approved
            if showTutorialOverlay && currentTutorialStep == .approveCard {
                let oldApprovedCount = oldCards.filter { $0.approved }.count
                let newApprovedCount = newCards.filter { $0.approved }.count
                
                if newApprovedCount > oldApprovedCount {
                    print("✓ Card approved - advancing from approveCard to goToQuiz")
                    advanceTutorial()
                }
            }
        }
    }
    
    private func advanceTutorial() {
        withAnimation {
            print("🎯 Advancing tutorial from: \(currentTutorialStep)")
            switch currentTutorialStep {
            case .welcome:
                currentTutorialStep = .viewDemoSets
                print("   → Now on: viewDemoSets")
            case .viewDemoSets:
                currentTutorialStep = .tapFirstSet
                print("   → Now on: tapFirstSet")
            case .tapFirstSet:
                currentTutorialStep = .viewFlashcards
                print("   → Now on: viewFlashcards")
            case .viewFlashcards:
                currentTutorialStep = .approveCard
                print("   → Now on: approveCard")
            case .approveCard:
                currentTutorialStep = .openStudyMode
                print("   → Now on: openStudyMode")
            case .openStudyMode:
                currentTutorialStep = .viewStudyList
                print("   → Now on: viewStudyList")
            case .viewStudyList:
                currentTutorialStep = .startPractice
                print("   → Now on: startPractice")
            case .startPractice:
                currentTutorialStep = .flipCard
                print("   → Now on: flipCard")
            case .flipCard:
                currentTutorialStep = .goToQuiz
                print("   → Now on: goToQuiz")
            case .goToQuiz:
                currentTutorialStep = .startQuiz
                print("   → Now on: startQuiz")
            case .startQuiz:
                currentTutorialStep = .complete
                print("   → Now on: complete")
            case .complete:
                print("   → Tutorial finished, closing overlay")
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
            // Give user 4 seconds to see the demo sets
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if self.currentTutorialStep == .viewDemoSets {
                    self.advanceTutorial()
                }
            }
        case .viewFlashcards:
            // Give user 5 seconds to see the flashcards view
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
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
            // Give user 3 seconds to see the study list
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.currentTutorialStep == .viewStudyList {
                    self.advanceTutorial()
                }
            }
        case .flipCard:
            // Give user 4 seconds to try flipping the card
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if self.currentTutorialStep == .flipCard {
                    self.advanceTutorial()
                }
            }
        case .startQuiz:
            // Give user 3 seconds to see the quiz
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if self.currentTutorialStep == .startQuiz {
                    self.advanceTutorial()
                }
            }
        default:
            break
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

//
//  AppState.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import SwiftUI
import Combine

// MARK: - App-wide navigation and coordination state

/// Central observable state that coordinates navigation, tutorial flow,
/// and cross-view communication throughout the app.
class AppState: ObservableObject {

    // MARK: - Tab & Split Navigation

    enum Tab: Hashable {
        case scan
        case savedSets
        case quiz
    }

    @Published var selectedTab: Tab = .scan
    @Published var splitVisibility: NavigationSplitViewVisibility = .all

    // MARK: - Quiz Entry

    @Published var isQuickQuizEntry: Bool = false

    // MARK: - Tutorial Coordination

    /// Set to `true` from SettingsView to tell ContentView to restart the onboarding tutorial.
    @Published var shouldRestartTutorial: Bool = false

    /// Timestamps used to detect when specific views appear during the tutorial.
    /// ContentView observes these to advance the tutorial step.
    @Published var setDetailViewAppeared: Date? = nil
    @Published var quizViewAppeared: Date? = nil
    @Published var studyViewAppeared: Date? = nil
    @Published var practiceViewAppeared: Date? = nil

    // MARK: - Scroll Coordination

    @Published var scrollToFlashcards: Bool = false

    // MARK: - Convenience

    /// Resets all transient navigation state back to defaults.
    /// Call this when the user finishes a flow and returns to the dashboard.
    func resetNavigation() {
        selectedTab = .scan
        isQuickQuizEntry = false
        scrollToFlashcards = false
        setDetailViewAppeared = nil
        quizViewAppeared = nil
        studyViewAppeared = nil
        practiceViewAppeared = nil
    }
}

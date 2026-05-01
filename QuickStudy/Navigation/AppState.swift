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

@Observable
class AppState {

    // MARK: - Tab & Split Navigation

    enum Tab: Hashable {
        case scan
        case savedSets
        case quiz
    }

    var selectedTab: Tab = .scan
    var splitVisibility: NavigationSplitViewVisibility = .all

    // MARK: - Quiz Entry

    var isQuickQuizEntry: Bool = false

    // MARK: - Tutorial Coordination

    /// Set to `true` from SettingsView to tell ContentView to restart the onboarding tutorial.
    var shouldRestartTutorial: Bool = false

    /// Timestamps used to detect when specific views appear during the tutorial.
    /// ContentView observes these to advance the tutorial step.
    var setDetailViewAppeared: Date? = nil
    var quizViewAppeared: Date? = nil
    var studyViewAppeared: Date? = nil
    var practiceViewAppeared: Date? = nil

    // MARK: - Scroll Coordination

     var scrollToFlashcards: Bool = false

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

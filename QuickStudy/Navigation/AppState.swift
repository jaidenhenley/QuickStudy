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

    // MARK: - Tab Navigation
    enum Tab: Hashable {
        case today
        case library
    }

    var selectedTab: Tab = .today

    // MARK: - Scroll Coordination
    var scrollToFlashcards: Bool = false

    // MARK: - Quiz Entry
    var isQuickQuizEntry: Bool = false

    func resetNavigation() {
        selectedTab = .today
        isQuickQuizEntry = false
        scrollToFlashcards = false
    }
}

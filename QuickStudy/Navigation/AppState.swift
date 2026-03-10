//
//  AppState.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import SwiftUI
import Combine

 class AppState: ObservableObject {
    @Published var splitVisibility: NavigationSplitViewVisibility = .all
    enum Tab: Hashable {
        case scan
        case savedSets
        case quiz
    }

    @Published var selectedTab: Tab = .scan
    @Published var isQuickQuizEntry: Bool = false
    @Published var setDetailViewAppeared: Date? = nil
    @Published var quizViewAppeared: Date? = nil
    @Published var studyViewAppeared: Date? = nil
    @Published var practiceViewAppeared: Date? = nil
    @Published var scrollToFlashcards: Bool = false
}

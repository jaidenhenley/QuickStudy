//
//  AppState.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import SwiftUI

 class AppState: ObservableObject {
    @Published var splitVisibility: NavigationSplitViewVisibility = .all
    enum Tab: Hashable {
        case scan
        case savedSets
        case quiz
    }

    @Published var selectedTab: Tab = .scan
    @Published var isQuickQuizEntry: Bool = false
}

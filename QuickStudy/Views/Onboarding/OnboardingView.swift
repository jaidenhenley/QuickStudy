//
//  OnboardingView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

enum TutorialStep: CustomStringConvertible {
    case welcome           // Initial welcome
    case viewDemoSets      // See the demo sets
    case tapFirstSet       // Tap on a study set
    case viewFlashcards    // See the generated cards
    case approveCard       // Approve a flashcard
    case openStudyMode     // Tap Study button
    case viewStudyList     // See the study list
    case startPractice     // Tap Start Practice
    case flipCard          // Try flipping a card
    case goToQuiz          // Navigate to quiz tab
    case startQuiz         // See quiz questions
    case complete          // Tutorial done
    
    var description: String {
        switch self {
        case .welcome: return "welcome"
        case .viewDemoSets: return "viewDemoSets"
        case .tapFirstSet: return "tapFirstSet"
        case .viewFlashcards: return "viewFlashcards"
        case .approveCard: return "approveCard"
        case .openStudyMode: return "openStudyMode"
        case .viewStudyList: return "viewStudyList"
        case .startPractice: return "startPractice"
        case .flipCard: return "flipCard"
        case .goToQuiz: return "goToQuiz"
        case .startQuiz: return "startQuiz"
        case .complete: return "complete"
        }
    }
}

// Welcome screen with Start/Skip options

// Circular timer indicator that shows countdown

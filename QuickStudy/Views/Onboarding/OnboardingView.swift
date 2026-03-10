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
struct WelcomeScreen: View {
    let onStart: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon/logo area
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.primary)
            
            VStack(spacing: 12) {
                Text("Welcome to QuickStudy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Turn your notes into study materials in seconds")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    onStart()
                } label: {
                    Text("Try Interactive Demo")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primary)
                        .cornerRadius(12)
                }
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip Tutorial")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}



struct TutorialOverlay: View {
    let step: TutorialStep
    let onNext: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        let _ = print("🎨 TutorialOverlay rendering with step: \(step)")
        VStack {
            Spacer()
            
            VStack(spacing: 20) {
                // Step indicator
                HStack(spacing: 6) {
                    ForEach(0..<totalSteps, id: \.self) { index in
                        Circle()
                            .fill(index <= stepNumber ? Theme.primary : Color.gray.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 4)
                
                // Icon for visual clarity with timer overlay if time-dependent
                ZStack {
                    Image(systemName: stepIcon)
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.primary)
                    
                    // Show timer for auto-advancing steps
                    if isTimedStep {
                        TimerIndicator(duration: stepDuration)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 4)
                
                // Clear step number and title
                VStack(spacing: 6) {
                    Text("Step \(stepNumber + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(1)
                    
                    Text(stepTitle)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                
                // Detailed instruction
                Text(stepInstruction)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
                
                // Action area - only show button on final step
                if step == .complete {
                    VStack(spacing: 12) {
                        Button {
                            onNext()
                        } label: {
                            HStack {
                                Text("Get Started")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.primary)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top, 4)
                } else {
                    // Show skip option for all other steps
                    Button {
                        onSkip()
                    } label: {
                        Text("Exit Tutorial")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
    
    private var stepNumber: Int {
        switch step {
        case .welcome: return 0  // Not shown in tutorial overlay
        case .viewDemoSets: return 0  // Step 1 in overlay
        case .tapFirstSet: return 1   // Step 2 in overlay
        case .viewFlashcards: return 2  // Step 3 in overlay
        case .approveCard: return 3   // Step 4 in overlay
        case .openStudyMode: return 4  // Step 5 in overlay
        case .viewStudyList: return 5  // Step 6 in overlay
        case .startPractice: return 6  // Step 7 in overlay
        case .flipCard: return 7       // Step 8 in overlay
        case .goToQuiz: return 8       // Step 9 in overlay
        case .startQuiz: return 9      // Step 10 in overlay
        case .complete: return 10      // Step 11 in overlay
        }
    }
    
    private var totalSteps: Int { 11 }
    
    private var stepIcon: String {
        switch step {
        case .welcome: return "hand.wave.fill"
        case .viewDemoSets: return "books.vertical.fill"
        case .tapFirstSet: return "hand.tap.fill"
        case .viewFlashcards: return "rectangle.stack.fill"
        case .approveCard: return "checkmark.circle.fill"
        case .openStudyMode: return "book.fill"
        case .viewStudyList: return "list.bullet"
        case .startPractice: return "play.circle.fill"
        case .flipCard: return "arrow.triangle.2.circlepath"
        case .goToQuiz: return "arrow.right.circle.fill"
        case .startQuiz: return "list.bullet.clipboard.fill"
        case .complete: return "checkmark.seal.fill"
        }
    }
    
    private var stepTitle: String {
        switch step {
        case .welcome:
            return "Welcome to QuickStudy!"
        case .viewDemoSets:
            return "Your Demo Study Sets"
        case .tapFirstSet:
            return "Open a Study Set"
        case .viewFlashcards:
            return "Review Flashcards"
        case .approveCard:
            return "Approve Cards"
        case .openStudyMode:
            return "Open Study Mode"
        case .viewStudyList:
            return "Your Study Cards"
        case .startPractice:
            return "Begin Practice"
        case .flipCard:
            return "Flip the Card"
        case .goToQuiz:
            return "Try the Quiz"
        case .startQuiz:
            return "Test Yourself"
        case .complete:
            return "You're All Set!"
        }
    }
    
    private var stepInstruction: String {
        switch step {
        case .welcome:
            return "We've loaded 3 demo study sets to show you how QuickStudy works. Let's explore!"
        case .viewDemoSets:
            return "Look at your home screen above. You'll see three demo sets: Human Interface Guidelines, SwiftUI, and SpriteKit. These were created from real documentation."
        case .tapFirstSet:
            return "Tap on any of the study sets above (try \"Human Interface Guidelines\") to open it and see the flashcards inside."
        case .viewFlashcards:
            return "Great! You're now viewing AI-generated flashcards. Each card has a question and answer. Swipe through a few to see different cards."
        case .approveCard:
            return "See the toggle buttons on each card? Tap one to approve a card. Approved cards will appear in your study and quiz. Try approving 2-3 cards now."
        case .openStudyMode:
            return "Perfect! Now tap the \"Study\" button above to practice with your approved cards."
        case .viewStudyList:
            return "Nice! Here are your approved cards. Only cards you approve will show up here for practice."
        case .startPractice:
            return "Now tap the \"Start Practice\" button to begin studying with the flashcard flip feature."
        case .flipCard:
            return "Tap on the card to flip it and reveal the answer! This is how you study - test yourself on the question, then flip to check your answer."
        case .goToQuiz:
            return "Great practice! Now let's go back and try the quiz. Tap the back button, then tap \"Open Quiz\"."
        case .startQuiz:
            return "Excellent! This is a multiple-choice quiz generated from your approved cards. Answer a question to see how it works, or tap continue to finish."
        case .complete:
            return "Tutorial complete! Demo mode is now off. You're ready to scan your own documents, import PDFs, or use photos to create study materials."
        }
    }
    
    private var isTimedStep: Bool {
        switch step {
        case .viewDemoSets, .viewFlashcards, .startQuiz:
            return true
        default:
            return false
        }
    }
    
    private var stepDuration: TimeInterval {
        switch step {
        case .viewDemoSets: return 4.0
        case .viewFlashcards: return 5.0
        case .startQuiz: return 3.0
        default: return 0
        }
    }

}
// Circular timer indicator that shows countdown
struct TimerIndicator: View {
    let duration: TimeInterval
    @State private var progress: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 3)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: duration), value: progress)
        }
        .onAppear {
            progress = 1.0
        }
    }
}


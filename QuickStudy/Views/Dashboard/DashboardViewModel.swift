//
//  DashboardViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentSource: Source?
    @Published var recentSets: [StudySet] = []
    @Published var pinnedSetIDs: Set<UUID> = []
    @Published var streakCount: Int = 0
    @Published var todayCardCount: Int = 0
    @Published var estimatedMin: Int = 0
    @Published var weakestCard: WeakestCardInfo? = nil
    @Published var aiCardsUsed: Int = 32
    @Published var aiCardsLimit: Int = 50
    
    private let defaults = UserDefaults.standard
    private let streakKey = "qs_streakCount"
    private let lastStudiedKey = "qs_lastStudiedDate"
    
    init() {
        loadStreak()
    }
    
    // MARK: Streak
    
    private func loadStreak() {
        streakCount = defaults.integer(forKey: streakKey)
    }
    
    func recordStudySessio() {
        let today = Calendar.current.startOfDay(for: Date())
        if let lastDate = defaults.object(forKey: lastStudiedKey) as? Date {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            guard let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day else { return }
            if diff == 1 {
                streakCount += 1
            } else if diff > 1 {
                streakCount = 1
            }
        } else {
            streakCount = 1
        }
        defaults.set(streakCount, forKey: streakKey)
        defaults.set(Date(), forKey: lastStudiedKey)
        
    }
    
    // MARK: Pins / Delete

    func togglePin(for set: StudySet) {
        if pinnedSetIDs.contains(set.id) {
            pinnedSetIDs.remove(set.id)
        } else {
            pinnedSetIDs.insert(set.id)
        }
    }

    func delete(set: StudySet) {
        recentSets.removeAll { $0.id == set.id }
        pinnedSetIDs.remove(set.id)
    }

    func updateFromStudy(_ studyViewModel: StudyViewModel) {
        let activeID = studyViewModel.activeSetID
        recentSets = studyViewModel.savedSets
            .filter { set in
                guard let activeID else { return true }
                return set.id != activeID
            }
            .sorted { $0.updatedAt > $1.updatedAt }

        if let document = studyViewModel.document {
            let title = document.title.isEmpty ? "Untitled Document" : document.title
            let progressText = "\(document.lines.count) lines"
            currentSource = Source(title: title, updatedAt: Date(), progressText: progressText)
        } else {
            currentSource = nil
        }
        
        computeTodaySession(from: studyViewModel.savedSets)
        computeWeakestCard(from: studyViewModel.savedSets)
    }
    
    
    // MARK: - Derived

    private func computeTodaySession(from sets: [StudySet]) {
        let approvedCards = sets.flatMap { $0.cards }.filter { $0.approved }
        todayCardCount = approvedCards.count
        estimatedMin = max(1, Int((Double(approvedCards.count) * 0.5).rounded()))
    }

    private func computeWeakestCard(from sets: [StudySet]) {
        var worst: (card: StudyCard, setID: UUID)? = nil
        for set in sets {
            for card in set.cards {
                if card.missCount > 0 {
                    if let current = worst {
                        if card.missCount > current.card.missCount {
                            worst = (card, set.id)
                        }
                    } else {
                        worst = (card, set.id)
                    }
                }
            }
        }
        if let worst {
            weakestCard = WeakestCardInfo(
                question: worst.card.question,
                missCount: worst.card.missCount,
                setID: worst.setID
            )
        } else {
            weakestCard = nil
        }
    }
}

struct Source: Identifiable, Equatable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let progressText: String

    init(
        id: UUID = UUID(),
        title: String,
        updatedAt: Date,
        progressText: String
    ) {
        self.id = id
        self.title = title
        self.updatedAt = updatedAt
        self.progressText = progressText
    }
}

struct WeakestCardInfo {
    let question: String
    let missCount: Int
    let setID: UUID
}


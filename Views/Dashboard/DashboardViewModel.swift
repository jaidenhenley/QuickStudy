//
//  DashboardViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 1/24/26.
//

import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var currentSource: Source?
    @Published var recentSets: [StudySet]
    @Published var pinnedSetIDs: Set<UUID>

    init(
        currentSource: Source? = nil,
        recentSets: [StudySet] = [],
        pinnedSetIDs: Set<UUID> = []
    ) {
        self.currentSource = currentSource
        self.recentSets = recentSets
        self.pinnedSetIDs = pinnedSetIDs
    }

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

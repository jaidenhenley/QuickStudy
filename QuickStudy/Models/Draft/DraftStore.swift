//
//  DraftStore.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.henley.jaiden.QuickStudy",
    category: "DraftStore"
)

@MainActor
@Observable
final class DraftStore {
    private(set) var pending: DraftSet?
    private(set) var loadIssue: PersistenceIssue?
    var isLoadIssuePresented = false

    private let file = JSONFile(named: "PendingDraft.json")

    var loadIssueMessage: String {
        switch loadIssue {
        case .corrupt:
            "Your unsaved draft couldn't be read. Create the set again from your notes. A copy of the original was kept on this iPhone."
        case .unreadable:
            "Your unsaved draft couldn't be opened right now. Restart QuickStudy to try again."
        case nil:
            ""
        }
    }

    init() {
        load()
    }

    func set(_ draft: DraftSet?) {
        pending = draft
        persist()
    }

    private func load() {
        switch file.load(DraftSet.self) {
        case .loaded(let draft):
            pending = draft
        case .missing:
            pending = nil
        case .failed(let issue):
            pending = nil
            loadIssue = issue
            isLoadIssuePresented = true
        }
    }

    private func persist() {
        guard loadIssue != .unreadable else { return }
        do {
            if let pending {
                try file.save(pending)
            } else {
                try file.remove()
            }
        } catch {
            logger.error("Failed to persist draft: \(error.localizedDescription)")
        }
    }
}

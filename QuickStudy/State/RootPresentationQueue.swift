//
//  RootPresentationQueue.swift
//  QuickStudy
//

import SwiftUI

@MainActor
@Observable
final class RootPresentationQueue {
    enum Item: Hashable {
        case onboarding, whatsNew, onboardingPaywall, libraryIssue, historyIssue, draftIssue
    }

    static let sheetSettle: Duration = .milliseconds(700)
    static let alertSettle: Duration = .milliseconds(400)

    private(set) var active: Item?

    @ObservationIgnored private var waiting: [Item] = []
    @ObservationIgnored private var holdUntil = ContinuousClock.now
    @ObservationIgnored private var advanceTask: Task<Void, Never>?

    func enqueue(_ item: Item, after delay: Duration = .zero) {
        guard active != item, !waiting.contains(item) else { return }
        waiting.append(item)
        hold(for: delay)
    }

    func isPresenting(_ item: Item, settle: Duration, onDismiss: @escaping () -> Void = {}) -> Binding<Bool> {
        Binding(
            get: { self.active == item },
            set: { shown in
                guard !shown, self.active == item else { return }
                self.active = nil
                onDismiss()
                self.hold(for: settle)
            }
        )
    }

    /// Presenting while another presentation is still animating out drops the new one, so
    /// the next item waits until the hold has passed.
    private func hold(for delay: Duration) {
        holdUntil = max(holdUntil, ContinuousClock.now + delay)
        advanceTask?.cancel()
        advanceTask = Task {
            do {
                try await Task.sleep(until: self.holdUntil, clock: .continuous)
            } catch {
                return
            }
            self.advance()
        }
    }

    private func advance() {
        guard active == nil, !waiting.isEmpty, ContinuousClock.now >= holdUntil else { return }
        active = waiting.removeFirst()
    }
}

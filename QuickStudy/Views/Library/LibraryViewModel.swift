//
//  LibraryViewModel.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import Foundation

@MainActor
@Observable
final class LibraryViewModel {
    enum AddCardsReason {
        case noOnDeviceModel
        case allowanceExhausted
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all
        case due
        case inProgress
        case mastered

        var id: String { rawValue }

        var label: String {
            switch self {
            case .all:
                return "All"
            case .due:
                return "Due"
            case .inProgress:
                return "In progress"
            case .mastered:
                return "Mastered"
            }
        }
    }

    var searchText = ""
    var filter: Filter = .all
    var isManualOnly = false
    var addCardsReason: AddCardsReason? = nil

    var showsAddCardsSection: Bool { addCardsReason != nil }

    // Only the exhausted surface tells the user their free generations are used up.
    var upgradeSurface: PaywallSurface { addCardsReason == .allowanceExhausted ? .exhausted : .pill }

    /// `AICapability` reads the Keychain, so this is refreshed on appear and on a
    /// mode change rather than evaluated from a view body. A device with no local model
    /// can still generate on the server while its free hosted generation is unspent and
    /// consent hasn't been declined.
    func refreshCapability(settings: AISettings, store: StoreController) {
        let noLocalModel = AICapability.state(for: settings) == .unsupportedDevice
        isManualOnly = noLocalModel && !store.isPro
            && (store.freeHostedGenerationUsed || HostedConsent.decision == .declined)

        if isManualOnly {
            addCardsReason = .noOnDeviceModel
        } else if !store.isPro && GenerationAllowance.isExhausted {
            addCardsReason = .allowanceExhausted
        } else {
            addCardsReason = nil
        }
    }

    func sets(from all: [StudySet], now: Date = Date(), calendar: Calendar = .current) -> [StudySet] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searched = query.isEmpty
            ? all
            : all.filter { $0.title.localizedCaseInsensitiveContains(query) }

        let filtered = searched.filter { set in
            switch filter {
            case .all:
                return true
            case .due:
                return set.dueCount(asOf: now, calendar: calendar) > 0
            case .inProgress:
                return set.masteryState == .inProgress
            case .mastered:
                return set.masteryState == .mastered
            }
        }

        return filtered.sorted { $0.updatedAt > $1.updatedAt }
    }
}

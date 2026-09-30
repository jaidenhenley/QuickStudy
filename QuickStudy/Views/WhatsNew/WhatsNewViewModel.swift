//
//  WhatsNewViewModel.swift
//  QuickStudy
//

import Foundation
import Observation

@MainActor
@Observable
final class WhatsNewViewModel: Identifiable {
    let note: ReleaseNote
    private(set) var showsProFeature = false
    private(set) var showsCloudNotice = false

    var id: Int { note.id }

    init(note: ReleaseNote) {
        self.note = note
    }

    func refresh(settings: AISettings, store: StoreController) {
        showsProFeature = note.proFeature != nil && !store.isPro
        showsCloudNotice = note.cloudNotice != nil
            && AIController.requiresHostedConsent(settings: settings, store: store)
    }
}

//
//  ImportFailure.swift
//  QuickStudy
//

import Foundation

struct ImportFailure: Identifiable {
    enum Recovery: Hashable {
        case pasteText
        case tryAgain
        case typeCards
    }

    let id = UUID()
    let title: String
    let message: String
    /// True when the coordinator still holds the text it read, so the paste recovery
    /// opens the sheet already filled in.
    let keepsText: Bool
    /// The first entry is the one Library offers as a button.
    let recoveries: [Recovery]
}

extension ImportFailure {
    var pasteRecoveryLabel: String { keepsText ? String(localized: "Edit Text") : String(localized: "Paste Text") }

    static func generation(cause: String?) -> ImportFailure {
        ImportFailure(
            title: String(localized: "Something went wrong"),
            message: cause ?? String(localized: "We couldn't draft cards from this source."),
            keepsText: true,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func noText(message: String) -> ImportFailure {
        ImportFailure(
            title: String(localized: "We couldn't read this"),
            message: message,
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func processing(message: String) -> ImportFailure {
        ImportFailure(
            title: String(localized: "Something went wrong"),
            message: message,
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func unreadablePDF() -> ImportFailure {
        ImportFailure(
            title: String(localized: "We couldn't open this PDF"),
            message: String(localized: "It may be damaged or password protected."),
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func quotaExhausted(resetDate: Date) -> ImportFailure {
        ImportFailure(
            title: String(localized: "Free generations used"),
            message: String(localized: "You've used all \(GenerationAllowance.monthlyLimit) free generations this month. They reset on \(resetDate.formatted(.dateTime.month(.wide).day()))."),
            keepsText: false,
            recoveries: []
        )
    }

    /// Apple Intelligence is off or still downloading. `Try again` would just repeat the
    /// same failure, so the only real recovery is typing cards by hand.
    static func deviceNotReady(message: String) -> ImportFailure {
        ImportFailure(
            title: String(localized: "On-device AI isn't ready"),
            message: message,
            keepsText: false,
            recoveries: [.typeCards]
        )
    }

    static let emptyPaste = ImportFailure(
        title: String(localized: "We couldn't read this"),
        message: String(localized: "Paste some notes to generate cards from."),
        keepsText: false,
        recoveries: [.pasteText]
    )
}

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
    var pasteRecoveryLabel: String { keepsText ? "Edit Text" : "Paste Text" }

    static func generation(cause: String?) -> ImportFailure {
        ImportFailure(
            title: "Something went wrong",
            message: cause ?? "We couldn't draft cards from this source.",
            keepsText: true,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func noText(message: String) -> ImportFailure {
        ImportFailure(
            title: "We couldn't read this",
            message: message,
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func processing(message: String) -> ImportFailure {
        ImportFailure(
            title: "Something went wrong",
            message: message,
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func unreadablePDF() -> ImportFailure {
        ImportFailure(
            title: "We couldn't open this PDF",
            message: "It may be damaged or password protected.",
            keepsText: false,
            recoveries: [.tryAgain, .pasteText]
        )
    }

    static func quotaExhausted(resetDate: Date) -> ImportFailure {
        ImportFailure(
            title: "Free generations used",
            message: "You've used all \(GenerationAllowance.monthlyLimit) free generations this month. They reset on \(resetDate.formatted(.dateTime.month(.wide).day())).",
            keepsText: false,
            recoveries: []
        )
    }

    /// Apple Intelligence is off or still downloading. `Try again` would just repeat the
    /// same failure, so the only real recovery is typing cards by hand.
    static func deviceNotReady(message: String) -> ImportFailure {
        ImportFailure(
            title: "On-device AI isn't ready",
            message: message,
            keepsText: false,
            recoveries: [.typeCards]
        )
    }

    static let emptyPaste = ImportFailure(
        title: "We couldn't read this",
        message: "Paste some notes to generate cards from.",
        keepsText: false,
        recoveries: [.pasteText]
    )
}

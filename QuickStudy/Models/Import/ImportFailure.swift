//
//  ImportFailure.swift
//  QuickStudy
//

import Foundation

struct ImportFailure: Identifiable {
    enum Severity {
        case error
        case warning
    }

    enum Recovery: Hashable {
        case pasteText
        case tryAgain
    }

    let id = UUID()
    let severity: Severity
    let navigationTitle: String
    let dismissLabel: String
    let title: String
    let message: String
    let recoveryNote: String?
    let code: String?
    let tips: [String]
    let recoveries: [Recovery]
}

extension ImportFailure {
    static func generation(cause: String?, code: String?, retainedNoun: String?) -> ImportFailure {
        ImportFailure(
            severity: .error,
            navigationTitle: "Error",
            dismissLabel: "Cancel",
            title: "Something went wrong",
            message: cause ?? "We couldn't draft cards from this source.",
            recoveryNote: retainedNoun.map {
                "Your \($0) was saved — you can try again or paste the text manually."
            },
            code: code ?? "QS-503",
            tips: [],
            recoveries: [.pasteText, .tryAgain]
        )
    }

    static func noText(navigationTitle: String, message: String) -> ImportFailure {
        ImportFailure(
            severity: .warning,
            navigationTitle: navigationTitle,
            dismissLabel: "Back",
            title: "We couldn't read this",
            message: message,
            recoveryNote: nil,
            code: nil,
            tips: [
                "Use a flat surface, no glare",
                "Fill the frame edge-to-edge",
                "Handwritten? Paste or type instead"
            ],
            recoveries: [.pasteText, .tryAgain]
        )
    }

    static func processing(message: String, code: String) -> ImportFailure {
        ImportFailure(
            severity: .error,
            navigationTitle: "Error",
            dismissLabel: "Cancel",
            title: "Something went wrong",
            message: message,
            recoveryNote: nil,
            code: code,
            tips: [],
            recoveries: [.pasteText, .tryAgain]
        )
    }

    static func quotaExhausted(resetDate: Date) -> ImportFailure {
        ImportFailure(
            severity: .warning,
            navigationTitle: "Free generations",
            dismissLabel: "Done",
            title: "Free generations used",
            message: "You've used all \(GenerationAllowance.monthlyLimit) free generations this month. They reset on \(resetDate.formatted(.dateTime.month(.wide).day())).",
            recoveryNote: nil,
            code: "QS-200",
            tips: [
                "Existing sets still work — study, quiz and edit as usual.",
                "Type cards by hand from the Library in the meantime."
            ],
            recoveries: []
        )
    }

    static let emptyPaste = ImportFailure(
        severity: .warning,
        navigationTitle: "Error",
        dismissLabel: "Cancel",
        title: "We couldn't read this",
        message: "Paste some notes to generate cards from.",
        recoveryNote: nil,
        code: nil,
        tips: [],
        recoveries: [.pasteText]
    )
}

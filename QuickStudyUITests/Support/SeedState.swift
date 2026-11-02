import Foundation

enum SeedState: String, CaseIterable {
    case freshInstall
    case onboardedEmpty
    case demoData
    case midDraft
    case userSet
    case proActive
    case allowanceSpent
    case hostedConsentDeclined
    case freeHostedSpent
    case noAppleIntelligence

    static let releaseSeen = "999"

    var launchArguments: [String] {
        switch self {
        case .freshInstall:
            return ["-QSResetInstall"]
        case .onboardedEmpty, .midDraft, .userSet:
            return Self.onboardedArguments
        case .demoData:
            return Self.onboardedArguments + ["-demoModeEnabled", "YES"]
        case .proActive:
            return Self.onboardedArguments
        case .allowanceSpent:
            return Self.onboardedArguments + [
                "-qs_aiGenerationsUsed", "10",
                "-qs_aiGenerationsMonth", String(Self.currentMonthStamp)
            ]
        case .hostedConsentDeclined:
            return Self.onboardedArguments + ["-qs_hostedConsent", "declined", "-qs_hostedConsentVersion", "3"]
        case .freeHostedSpent:
            return Self.onboardedArguments + ["-qs_hostedFreeGenerationUsed", "YES"]
        case .noAppleIntelligence:
            return Self.onboardedArguments
        }
    }

    var environment: [String: String] {
        switch self {
        case .noAppleIntelligence:
            return ["QS_SIMULATE_NO_APPLE_INTELLIGENCE": "1"]
        default:
            return [:]
        }
    }

    /// States that cannot be reached by launch arguments alone: run Scripts/seed.sh first.
    var needsFileSeed: Bool {
        self == .midDraft || self == .userSet
    }

    /// States that need a StoreKit purchase made by the runner before launch.
    var needsPurchase: Bool {
        self == .proActive
    }

    /// Wipes the install on launch, so the app must not be relaunched with these arguments.
    var resetsInstall: Bool {
        self == .freshInstall
    }

    private static var onboardedArguments: [String] {
        ["-qs_hasCompletedOnboarding", "YES", "-qs_lastSeenRelease", releaseSeen]
    }

    /// Mirrors GenerationAllowance.monthStamp(for:).
    static var currentMonthStamp: Int {
        let parts = Calendar.current.dateComponents([.year, .month], from: Date())
        return (parts.year ?? 0) * 12 + (parts.month ?? 0)
    }
}

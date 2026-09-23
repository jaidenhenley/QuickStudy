//
//  OnboardingViewModel.swift
//  QuickStudy
//

import AVFoundation
import Foundation

@MainActor
@Observable
final class OnboardingViewModel {
    enum Page: Hashable {
        case welcome, howItWorks, aiIntro, camera, firstSource
    }

    enum Choice: Equatable {
        case demo
        case source(ImportCoordinator.ImportSource)
    }

    private static let completedKey = "qs_hasCompletedOnboarding"
    private static let paywallPendingKey = "qs_onboardingPaywallPending"

    static var hasCompleted: Bool { UserDefaults.standard.bool(forKey: completedKey) }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

    /// Set when onboarding ends and cleared once the paywall shows after the user's first
    /// real set. Persisted so killing the app between the two doesn't lose the moment.
    static var isPaywallPending: Bool { UserDefaults.standard.bool(forKey: paywallPendingKey) }

    static func setPaywallPending(_ pending: Bool) {
        UserDefaults.standard.set(pending, forKey: paywallPendingKey)
    }

    let pages: [Page]
    let hasOnDeviceModel: Bool
    var current: Page = .welcome
    private(set) var choice: Choice?

    var currentIndex: Int { pages.firstIndex(of: current) ?? 0 }

    init(settings: AISettings) {
        hasOnDeviceModel = AICapability.state(for: settings) != .unsupportedDevice
        // A pre-permission card only earns its place before the system has asked.
        let cameraUndecided = AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined
        pages = [.welcome, .howItWorks, .aiIntro] + (cameraUndecided ? [.camera] : []) + [.firstSource]
    }

    func advance() {
        guard let index = pages.firstIndex(of: current), index + 1 < pages.count else { return }
        current = pages[index + 1]
    }

    func requestCameraAccess() async {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        advance()
    }

    func choose(_ choice: Choice) {
        self.choice = choice
        Self.markCompleted()
    }
}

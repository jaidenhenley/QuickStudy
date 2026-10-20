//
//  EngineRoutingTests.swift
//  QuickStudyTests
//

import Testing
@testable import QuickStudy

/// One test per kind of iPhone and user, so a change to the plan can't quietly break a
/// path that no simulator can show.
struct EngineRoutingTests {
    private static let short = 2_000
    private static let midLength = AIController.proPrivateCloudLimit + 1
    private static let overServerLimit = HostedCardGenerationEngine.maxInputLength + 1

    /// iOS 27 with Apple Intelligence on and PCC ready, a consented free user who has
    /// not used the free hosted generation. Each test changes only what it is about.
    private static func conditions(
        mode: CardGenerationMode = .onDevice,
        consent: HostedConsent.Decision? = .granted,
        isPro: Bool = false,
        freeHostedGenerationUnused: Bool = true,
        hasOnDeviceModel: Bool = true,
        privateCloudReady: Bool = true
    ) -> DraftingConditions {
        DraftingConditions(
            mode: mode,
            consent: consent,
            isPro: isPro,
            freeHostedGenerationUnused: freeHostedGenerationUnused,
            hasOnDeviceModel: hasOnDeviceModel,
            privateCloudReady: privateCloudReady
        )
    }

    @Test func freeUserOnAPrivateCloudIPhoneSkipsTheServer() {
        #expect(AIController.plan(for: Self.conditions(), sourceLength: Self.short) == [.privateCloud, .onDevice])
    }

    @Test func freeUserOnIOS26GetsOneServerDraftThenOnDevice() {
        let first = Self.conditions(privateCloudReady: false)
        #expect(AIController.plan(for: first, sourceLength: Self.short) == [.cloud, .onDevice])

        let later = Self.conditions(freeHostedGenerationUnused: false, privateCloudReady: false)
        #expect(AIController.plan(for: later, sourceLength: Self.short) == [.onDevice])
    }

    /// iPhone 15 and older: no on-device model and no PCC. After the free server draft the
    /// on-device engine is still planned, and its availability error routes to manual cards.
    @Test func freeUserWithoutAppleIntelligenceGetsOneServerDraft() {
        let first = Self.conditions(hasOnDeviceModel: false, privateCloudReady: false)
        #expect(AIController.plan(for: first, sourceLength: Self.short) == [.cloud])

        let later = Self.conditions(freeHostedGenerationUnused: false, hasOnDeviceModel: false, privateCloudReady: false)
        #expect(AIController.plan(for: later, sourceLength: Self.short) == [.onDevice])
    }

    @Test func nothingLeavesTheIPhoneWithoutConsent() {
        for consent in [nil, HostedConsent.Decision.declined] {
            #expect(AIController.plan(for: Self.conditions(consent: consent), sourceLength: Self.short) == [.onDevice])
            #expect(AIController.plan(for: Self.conditions(consent: consent, isPro: true), sourceLength: Self.short) == [.onDevice])
        }
    }

    @Test func proPicksTheEngineByDocumentLength() {
        let pro = Self.conditions(isPro: true)
        #expect(AIController.plan(for: pro, sourceLength: Self.short) == [.privateCloud, .cloud, .onDevice])
        #expect(AIController.plan(for: pro, sourceLength: Self.midLength) == [.cloud, .onDevice])
        #expect(AIController.plan(for: pro, sourceLength: Self.overServerLimit) == [.privateCloud, .onDevice])
    }

    @Test func proWithoutPrivateCloudUsesTheServer() {
        let iOS26 = Self.conditions(isPro: true, privateCloudReady: false)
        #expect(AIController.plan(for: iOS26, sourceLength: Self.short) == [.cloud, .onDevice])

        let noAppleIntelligence = Self.conditions(isPro: true, hasOnDeviceModel: false, privateCloudReady: false)
        #expect(AIController.plan(for: noAppleIntelligence, sourceLength: Self.short) == [.cloud])
        #expect(AIController.plan(for: noAppleIntelligence, sourceLength: Self.overServerLimit) == [.cloud])
    }

    /// A used-up daily quota reads as "not ready", so the iPhone is routed as if it had no PCC.
    @Test func privateCloudQuotaReachedFallsBackLikeAnIPhoneWithoutIt() {
        let quotaReached = Self.conditions(freeHostedGenerationUnused: false, privateCloudReady: false)
        #expect(AIController.plan(for: quotaReached, sourceLength: Self.short) == [.onDevice])
    }

    @Test func ownAPIKeyIsTheOnlyEngine() {
        let ownKey = Self.conditions(mode: .externalAPI, isPro: true)
        #expect(AIController.plan(for: ownKey, sourceLength: Self.short) == [.externalAPI])
    }
}

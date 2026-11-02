import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var isCloudDraftingOn = HostedConsent.decision == .granted

    func refreshCloudDrafting() {
        isCloudDraftingOn = HostedConsent.decision == .granted
    }

    func setCloudDrafting(_ isOn: Bool) {
        HostedConsent.record(isOn ? .granted : .declined)
        isCloudDraftingOn = isOn
    }
}

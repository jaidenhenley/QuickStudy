//
//  AnalyticsRecorder.swift
//  QuickStudy
//

import Foundation

/// Aggregate, privacy-preserving funnel counters posted to the owner's own Worker —
/// counts and buckets only, never source text, card text, or a per-user identifier
/// beyond the App Attest key already used for `/generate`.
///
/// Call `record(_:)` for each event as it happens and `flush()` on session end or
/// backgrounding, mirroring how `StudyViewModel` batches answer writes. Counters live
/// in memory and are mirrored to UserDefaults on every `record(_:)` so a crash before
/// the next flush doesn't lose them.
@MainActor
@Observable
final class AnalyticsRecorder {
    private static let enabledKey = "qs_metrics_enabled"
    private static let snapshotKey = "qs_metrics_snapshot"
    private static let installDateKey = "qs_metrics_installDate"
    private static let firstGenerationKey = "qs_metrics_firstGenerationRecorded"

    private(set) var isEnabled: Bool
    private(set) var snapshot: MetricsSnapshot

    @ObservationIgnored private var isDirty: Bool
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let api: HostedAPI

    init(defaults: UserDefaults = .standard, api: HostedAPI = .configured()) {
        self.defaults = defaults
        self.api = api
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true

        // Corrupt or pre-migration data just starts a fresh snapshot rather than crashing.
        let loaded = defaults.data(forKey: Self.snapshotKey)
            .flatMap { try? JSONDecoder().decode(MetricsSnapshot.self, from: $0) } ?? MetricsSnapshot()
        snapshot = loaded
        isDirty = loaded != MetricsSnapshot()

        if defaults.object(forKey: Self.installDateKey) == nil {
            defaults.set(Date(), forKey: Self.installDateKey)
        }
    }

    /// Opt-out toggle backing the Settings row. Turning it off drops whatever hasn't
    /// been sent yet — nothing about the current session should linger once declined.
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.enabledKey)
        guard !enabled else { return }
        snapshot = MetricsSnapshot()
        isDirty = false
        defaults.removeObject(forKey: Self.snapshotKey)
    }

    func record(_ event: AnalyticsEvent) {
        guard isEnabled else { return }

        // Both of these are "once ever" facts the call site shouldn't have to track.
        if case .firstGenerationCompleted = event {
            guard !defaults.bool(forKey: Self.firstGenerationKey) else { return }
            defaults.set(true, forKey: Self.firstGenerationKey)
        }
        if case .paywallShown = event {
            snapshot.daysSinceInstallAtPaywall = daysSinceInstall()
        }

        snapshot.apply(event)
        isDirty = true
        persist()
    }

    private func daysSinceInstall(now: Date = Date(), calendar: Calendar = .current) -> Int {
        guard let installed = defaults.object(forKey: Self.installDateKey) as? Date else { return 0 }
        return max(0, calendar.dateComponents([.day], from: installed, to: now).day ?? 0)
    }

    func flush() async {
        guard isEnabled, isDirty else { return }
        let pending = snapshot

        // Analytics must never surface an error or block the app; a failed post is
        // dropped silently and the same counts simply carry into the next flush.
        guard let response = try? await post(pending), response.ok, snapshot == pending else { return }

        snapshot = MetricsSnapshot()
        isDirty = false
        defaults.removeObject(forKey: Self.snapshotKey)
    }

    private func post(_ snapshot: MetricsSnapshot) async throws -> HostedAPI.MetricsResponse {
        let challenge = try await api.challenge()
        var outgoing = snapshot
        outgoing.challenge = challenge
        let body = try JSONEncoder().encode(outgoing)
        // The exact bytes that are signed are the bytes that are sent, same as /generate.
        let signature = HostedAPI.developmentBypassToken == nil
            ? try await AppAttestClient.shared.sign(body, using: api)
            : nil
        return try await api.postMetrics(signedBody: body, signature: signature)
    }

    private func persist() {
        // Snapshot fields are all Int/Bool/String? — encoding cannot fail in practice.
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.snapshotKey)
    }
}

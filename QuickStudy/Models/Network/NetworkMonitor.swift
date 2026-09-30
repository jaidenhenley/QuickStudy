//
//  NetworkMonitor.swift
//  QuickStudy
//

import Foundation
import Network

@MainActor
@Observable
final class NetworkMonitor {
    private(set) var isOnline = true

    private let monitor = NWPathMonitor()
    // NWPathMonitor has no async interface — start(queue:) is the only entry point.
    private let queue = DispatchQueue(label: "com.quickstudy.network-monitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            Task { @MainActor in self?.isOnline = online }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

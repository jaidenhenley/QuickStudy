//
//  FreshInstallReset.swift
//  QuickStudy
//

#if DEBUG
import Foundation

/// Launch with `-QSResetInstall` to start from the state of a fresh App Store download.
/// Deleting the app isn't enough: the Keychain survives it, and with it the App Attest key
/// the server uses to remember that this device already spent its free cloud generation.
enum FreshInstallReset {
    static let launchArgument = "-QSResetInstall"

    static func performIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains(launchArgument) else { return }
        do {
            try KeychainManager.deleteAllItems()
            if let domain = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: domain)
            }
            let fileManager = FileManager.default
            let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            for url in try fileManager.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil) {
                try fileManager.removeItem(at: url)
            }
        } catch {
            assertionFailure("Fresh-install reset failed: \(error)")
        }
    }
}
#endif

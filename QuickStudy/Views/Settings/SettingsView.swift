//
//  SettingsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/26/26.
//

import SwiftUI
 
struct SettingsView: View {
    @EnvironmentObject var studyViewModel: StudyViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false

    @State private var showOnboarding = false
    @State private var showClearDataAlert = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AI + Input") {
                    Toggle("Handwriting Mode", isOn: $studyViewModel.isHandwritingMode)
                    Toggle("Spell Check", isOn: $studyViewModel.isSpellCheckEnabled)
                }

                Section("Help") {
                    Button("How to use QuickStudy") {
                        showOnboarding = true
                    }
                }

                Section {
                    Button("Delete All Study Sets", role: .destructive) {
                        showClearDataAlert = true
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("This will permanently delete all saved study sets and cards.")
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            WelcomeScreen(
                onStart: {
                    showOnboarding = false
                    // Dismiss the Settings sheet, then signal ContentView to start the tutorial
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        dismiss()
                        appState.shouldRestartTutorial = true
                    }
                },
                onSkip: {
                    showOnboarding = false
                }
            )
        }
        .alert("Delete All Data", isPresented: $showClearDataAlert) {
            Button("Delete Everything", role: .destructive) {
                studyViewModel.savedSets.removeAll()
                studyViewModel.document = nil
                studyViewModel.flashcards = []
                studyViewModel.activeSetID = nil
                studyViewModel.saveSavedSets()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all of your study sets and cards. This action cannot be undone.")
        }
    }
}

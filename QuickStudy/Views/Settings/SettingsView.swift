//
//  SettingsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/26/26.
//

import SwiftUI
 
struct SettingsView: View {
    @EnvironmentObject var studyViewModel: StudyViewModel
    @EnvironmentObject var aiSettings: AISettings
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
    
    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { aiSettings.apiKey ?? "" },
            set: { newValue in
                try? KeychainManager.saveAPIKey(newValue)
            }
        )
    }

    private var modelNameBinding: Binding<String> {
        Binding(
            get: { aiSettings.modelName ?? "" },
            set: { newValue in
                let cleaned = newValue
                    .replacingOccurrences(of: "\u{200B}", with: "")
                    .replacingOccurrences(of: "\u{FEFF}", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                aiSettings.modelName = cleaned.isEmpty ? nil : cleaned
            }
        )
    }

    private var endpointBinding: Binding<String> {
        Binding(
            get: { aiSettings.endpoint?.absoluteString ?? "" },
            set: { newValue in
                // Strip zero-width spaces and other invisible Unicode characters
                let cleaned = newValue.filter { !$0.isWhitespace || $0 == " " }
                    .replacingOccurrences(of: "\u{200B}", with: "")
                    .replacingOccurrences(of: "\u{FEFF}", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                aiSettings.endpoint = URL(string: cleaned)
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("AI + Input") {
                    Toggle("Handwriting Mode", isOn: $studyViewModel.isHandwritingMode)
                    Toggle("Spell Check", isOn: $studyViewModel.isSpellCheckEnabled)
                    
                    Picker("AI Source", selection: $aiSettings.mode) {
                        Text("On-Device").tag(CardGenerationMode.onDevice)
                        Text("External API").tag(CardGenerationMode.externalAPI)
                    }
                    
                    if aiSettings.mode == .externalAPI {
                        Picker("API Provider", selection: $aiSettings.apiFormat) {
                            Text("OpenAI").tag(APIFormat.openAI)
                            Text("Anthropic").tag(APIFormat.anthropic)
                        }
                        
                        SecureField("API Key", text: apiKeyBinding)
                        TextField("Endpoint URL", text: endpointBinding)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Model Name", text: modelNameBinding)
                    }
                    
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
            .onChange(of: aiSettings.apiFormat) { _, newFormat in
                switch newFormat {
                case .openAI:
                    if aiSettings.endpoint == nil || aiSettings.endpoint?.host() == "api.anthropic.com" {
                        aiSettings.endpoint = URL(string: "https://api.openai.com/v1/chat/completions")
                    }
                    if aiSettings.modelName == nil || aiSettings.modelName?.hasPrefix("claude") == true {
                        aiSettings.modelName = "gpt-4.1-mini"
                    }
                case .anthropic:
                    if aiSettings.endpoint == nil || aiSettings.endpoint?.host() == "api.openai.com" {
                        aiSettings.endpoint = URL(string: "https://api.anthropic.com/v1/messages")
                    }
                    if aiSettings.modelName == nil || aiSettings.modelName?.hasPrefix("gpt") == true {
                        aiSettings.modelName = "claude-sonnet-4-20250514"
                    }
                }
            }
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

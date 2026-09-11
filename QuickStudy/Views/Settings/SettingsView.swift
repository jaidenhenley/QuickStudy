//
//  SettingsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/26/26.
//

import SwiftUI
 
struct SettingsView: View {
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(AISettings.self) var aiSettings
    @Environment(AppState.self) var appState
    @State private var showClearDataAlert = false
    @State private var apiKeyDraft = ""
    @State private var keychainErrorMessage: String?
    @State private var showKeychainError = false
    @FocusState private var apiKeyFocused: Bool

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func commitAPIKey() {
        do {
            try KeychainManager.saveAPIKey(apiKeyDraft)
        } catch {
            keychainErrorMessage = error.localizedDescription
            showKeychainError = true
        }
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
        @Bindable var studyViewModel = studyViewModel
        @Bindable var aiSettings = aiSettings
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
                        
                        SecureField("API Key", text: $apiKeyDraft)
                            .focused($apiKeyFocused)
                            .onChange(of: apiKeyFocused) { _, isFocused in
                                if !isFocused { commitAPIKey() }
                            }
                            .onSubmit { commitAPIKey() }
                        TextField("Endpoint URL", text: endpointBinding)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        TextField("Model Name", text: modelNameBinding)
                    }
                    
                }

                Section {
                    Toggle("Show Sample Sets", isOn: $studyViewModel.demoModeEnabled)
                } header: {
                    Text("Sample Content")
                } footer: {
                    Text("Adds three example sets you can study right away. Turning this off removes them; turning it back on restores them.")
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
            .onAppear { apiKeyDraft = aiSettings.apiKey ?? "" }
            .alert("Couldn't Save API Key", isPresented: $showKeychainError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(keychainErrorMessage ?? "Please try again.")
            }
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

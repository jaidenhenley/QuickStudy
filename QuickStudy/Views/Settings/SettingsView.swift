//
//  SettingsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/26/26.
//

import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(StudyViewModel.self) var studyViewModel
    @Environment(AISettings.self) var aiSettings
    @Environment(AppState.self) var appState
    @Environment(StoreController.self) var store
    @Environment(AnalyticsRecorder.self) var analytics
    @State private var showClearDataAlert = false
    @State private var showPaywall = false
    @State private var showManageSubscription = false
    @State private var apiKeyDraft = ""
    @State private var keychainErrorMessage: String?
    @State private var showKeychainError = false
    @State private var showExternalAPIConfirmation = false
    @State private var pendingAPIMode: CardGenerationMode?
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

    private var analyticsBinding: Binding<Bool> {
        Binding(
            get: { analytics.isEnabled },
            set: { analytics.setEnabled($0) }
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
                Section {
                    Toggle("Handwriting Mode", isOn: $studyViewModel.isHandwritingMode)
                    Toggle("Spell Check", isOn: $studyViewModel.isSpellCheckEnabled)

                    Picker("AI Source", selection: Binding(
                        get: { aiSettings.mode },
                        set: { newValue in
                            if newValue == .externalAPI && aiSettings.mode != .externalAPI {
                                pendingAPIMode = newValue
                                showExternalAPIConfirmation = true
                            } else {
                                aiSettings.mode = newValue
                            }
                        }
                    )) {
                        Text(store.isPro ? "QuickStudy's Server" : "On-Device").tag(CardGenerationMode.onDevice)
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
                } header: {
                    Text("AI + Input")
                } footer: {
                    if aiSettings.mode == .externalAPI {
                        Text("Your notes will be sent to your chosen provider using your key, under that provider's privacy policy.")
                    }
                }

                Section {
                    if store.isPro {
                        HStack {
                            Text("QuickStudy Pro")
                            Spacer()
                            Text("Active")
                                .foregroundStyle(.secondary)
                        }
                        Button("Manage Subscription") { showManageSubscription = true }
                    } else {
                        Button("Upgrade to QuickStudy Pro") { showPaywall = true }
                    }
                } header: {
                    Text("Pro")
                } footer: {
                    Text(store.isPro
                         ? "Cards are generated on QuickStudy's server. Your text isn't stored."
                         : "Better cards on any iPhone, generated in the cloud.")
                }

                Section {
                    Toggle("Show Sample Sets", isOn: $studyViewModel.demoModeEnabled)
                } header: {
                    Text("Sample Content")
                } footer: {
                    Text("Adds four example sets you can study right away. Turning this off removes them; turning it back on restores them.")
                }

                Section {
                    Toggle("Share anonymous usage", isOn: analyticsBinding)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Sends anonymous counts — like whether onboarding finished or a paywall was shown — to help improve QuickStudy. Never card text, never document text.")
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
                    Link("Privacy Policy", destination: LegalLinks.privacyPolicyURL)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView(surface: .settings) }
            .manageSubscriptionsSheet(isPresented: $showManageSubscription)
            .onAppear { apiKeyDraft = aiSettings.apiKey ?? "" }
            .confirmationDialog("Use External API", isPresented: $showExternalAPIConfirmation) {
                Button("Use External API") {
                    if let mode = pendingAPIMode {
                        aiSettings.mode = mode
                    }
                    pendingAPIMode = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingAPIMode = nil
                }
            } message: {
                Text("Your notes will be sent to your chosen provider using your key, under that provider's privacy policy.")
            }
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

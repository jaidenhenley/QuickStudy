//
//  SettingsView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/26/26.
//

import SwiftUI
 
struct SettingsView: View {
    @EnvironmentObject var studyViewModel: StudyViewModel
    @AppStorage("didShowOnboarding") private var didShowOnboarding = false

    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                Section("AI + Input") {
                    Toggle("Handwriting Mode", isOn: $studyViewModel.isHandwritingMode)
                    Toggle("Spell Check", isOn: $studyViewModel.isSpellCheckEnabled)
                }

                Section("Demo") {
                    Toggle("Demo Mode", isOn: $studyViewModel.demoModeEnabled)
                }

                Section("Help") {
                    Button("How to use QuickStudy") {
                        showOnboarding = true
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(
                onDismiss: {
                    didShowOnboarding = true
                    showOnboarding = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
}

//
//  WelcomeScreen.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

struct WelcomeScreen: View {
    let onStart: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // App icon/logo area
            Image(systemName: "graduationcap.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.primary)
            
            VStack(spacing: 12) {
                Text("Welcome to QuickStudy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Turn your notes into study materials in seconds")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                Button {
                    onStart()
                } label: {
                    Text("Try Interactive Demo")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primary)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Try interactive demo")
                .accessibilityHint("Starts a guided tutorial of the app")
                
                Button {
                    onSkip()
                } label: {
                    Text("Skip Tutorial")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Skip tutorial")
                .accessibilityHint("Skips the tutorial and goes straight to the app")
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }
}

//
//  OnboardingCameraPage.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingCameraPage: View {
    let onAllow: () -> Void
    let onLater: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "camera")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Color.appPrimary, in: RoundedRectangle(cornerRadius: AppRadius.xl))
                .shadow(color: Color.appPrimary.opacity(0.35), radius: 16, y: 8)

            VStack(spacing: Spacing.sm) {
                Text("Snap your notes")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("We'll ask for camera access next. Photos are read on this iPhone; the text from them helps draft your cards.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Spacing.md) {
                Button(action: onAllow) {
                    Text("Allow camera access")
                        .frame(maxWidth: .infinity)
                }
                .appProminentButtonStyle(tint: Theme.primary)
                .controlSize(.large)

                Button("Maybe later", action: onLater)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xl)
    }
}

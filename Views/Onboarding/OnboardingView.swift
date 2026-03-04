//
//  OnboardingView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import SwiftUI

struct OnboardingView: View {
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("How to try QuickStudy")
                        .font(.title2)
                        .fontWeight(.bold)

                }

                VStack(alignment: .leading, spacing: 12) {
                    stepRow("Scan or Import", detail: "Bring in notes or a PDF")
                    stepRow("Generate Cards", detail: "Use Apple Intelligence to create cards")
                    stepRow("Approve Cards", detail: "Toggle the ones you want in the quiz")
                    stepRow("Save Set", detail: "Keep your study set organized")
                    stepRow("Start Quiz", detail: "Practice with your approved cards")
                }
            }
            .padding(20)
            .frame(maxWidth: 520)
            .fixedSize(horizontal: false, vertical: true)
            .padding(24)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Got it") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private func stepRow(_ title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Theme.primary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

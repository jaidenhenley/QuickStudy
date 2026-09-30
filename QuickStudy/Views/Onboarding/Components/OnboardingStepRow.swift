//
//  OnboardingStepRow.swift
//  QuickStudy
//

import SwiftUI

struct OnboardingStepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.base) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.appPrimary)
                .frame(width: 36, height: 36)
                .background(Color.appPrimary.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

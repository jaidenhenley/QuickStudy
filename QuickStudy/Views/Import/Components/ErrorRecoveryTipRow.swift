//
//  ErrorRecoveryTipRow.swift
//  QuickStudy
//

import SwiftUI

struct ErrorRecoveryTipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            Circle()
                .fill(Theme.primary)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.subheadline)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.base)
    }
}

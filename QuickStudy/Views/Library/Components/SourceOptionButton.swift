//
//  SourceOptionButton.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct SourceOptionButton: View {
    let title: String
    let systemImage: String
    var isProminent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundStyle(isProminent ? Color.white : Color.appPrimary)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isProminent ? Color.white : Theme.textPrimary)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(isProminent ? Color.appPrimary : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(isProminent ? 0.18 : 0.05), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

//
//  FloatingCreateButton.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct FloatingCreateButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Theme.onPrimary)
                .frame(width: 56, height: 56)
                .glassEffect(.regular.tint(Theme.primary).interactive(), in: .circle)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .accessibilityLabel("New Set")
    }
}

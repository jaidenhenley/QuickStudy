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
            // Fixed size: the design pins the button to 56pt, so a Dynamic Type
            // glyph would outgrow the circle.
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.appPrimary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
        }
        .accessibilityLabel("New set")
    }
}

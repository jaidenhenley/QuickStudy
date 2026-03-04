//
//  CardContentView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/5/26.
//

import SwiftUI

struct CardContentView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.title2)
            .multilineTextAlignment(.center)
            .padding()
            .frame(width: 320, height: 200)
            .appGlassCard(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(color.opacity(0.35), lineWidth: 2)
            )
    }
}

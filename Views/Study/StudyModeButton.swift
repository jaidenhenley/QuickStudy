//
//  StudyModeButton.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/19/26.
//

import SwiftUI

struct StudyModeButton: View {
    let title: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .appGlassCard(cornerRadius: 15)
            .foregroundStyle(color)
        }
    }
}

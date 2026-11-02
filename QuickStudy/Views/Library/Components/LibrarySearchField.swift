//
//  LibrarySearchField.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct LibrarySearchField: View {
    @Binding var text: String
    var isEnabled: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Search sets", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(!isEnabled)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(minHeight: 44)
        .appGlassCard(cornerRadius: AppRadius.md)
        .opacity(isEnabled ? 1 : 0.6)
    }
}

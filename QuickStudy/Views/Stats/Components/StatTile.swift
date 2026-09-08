//
//  StatTile.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/8/26.
//

import SwiftUI

struct StatTile: View {
    let value: String
    let label: String
    var tint: Color = .appPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.base)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
    }
}

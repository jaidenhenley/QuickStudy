//
//  SourceTile.swift
//  QuickStudy
//

import SwiftUI

struct SourceTile: View {
    let systemImage: String
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var size = 36.0

    var body: some View {
        Image(systemName: systemImage)
            .font(.body)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .accessibilityHidden(true)
    }
}

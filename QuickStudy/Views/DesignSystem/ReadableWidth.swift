//
//  ReadableWidth.swift
//  QuickStudy
//

import SwiftUI

extension View {
    // Tab roots pass .leading so the column stays under the navigation bar's large title,
    // which cannot be inset to follow a centered column.
    func appReadableWidth(alignment: Alignment = .center) -> some View {
        frame(maxWidth: AppLayout.readableWidth)
            .frame(maxWidth: .infinity, alignment: alignment)
    }
}

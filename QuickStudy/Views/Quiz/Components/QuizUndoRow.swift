//
//  QuizUndoRow.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 10/22/26.
//

import SwiftUI

struct QuizUndoRow: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Text("We'll surface this one again tomorrow.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button(action: action) {
                Text("Undo")
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .font(.caption)
            .fontWeight(.semibold)
            .accessibilityHint("Returns to the question so you can answer again")
        }
    }
}

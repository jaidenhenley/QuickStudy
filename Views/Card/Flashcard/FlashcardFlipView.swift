//
//  FlashcardFlipView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/5/26.
//

import SwiftUI

struct FlashcardFlipView: View {
    let card: StudyCard
    @State private var isFlipped = false

    var body: some View {
        ZStack {
            CardContentView(text: card.question, color: .blue)
                .opacity(isFlipped ? 0 : 1)

            CardContentView(text: card.answer, color: .green)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFlipped)
        .contentShape(Rectangle())
        .onTapGesture {
            isFlipped.toggle()
        }
    }
}


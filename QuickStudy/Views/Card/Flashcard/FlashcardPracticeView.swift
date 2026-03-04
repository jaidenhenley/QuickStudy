//
//  FlashcardPracticeView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/10/26.
//

import SwiftUI

struct FlashcardPracticeView: View {
    let cards: [StudyCard]
    @State private var currentIndex = 0
    
    private var lastIndex: Int {
        max(0, cards.count - 1)
    }

    private var currentCard: StudyCard? {
        guard cards.indices.contains(currentIndex) else { return nil }
        return cards[currentIndex]
    }

    var body: some View {
        ZStack {
            BackgroundView()
                .ignoresSafeArea()

            VStack(spacing: 20) {
                if let card = currentCard {
                    FlashcardFlipView(card: card)
                        .id(card.id)

                    Text("Card \(currentIndex + 1) of \(cards.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        Button("Previous") {
                            guard !cards.isEmpty else { return }
                            currentIndex = max(0, currentIndex - 1)
                        }
                        .buttonStyle(.bordered)
                        .disabled(currentIndex == 0)

                        Button("Next") {
                            guard !cards.isEmpty else { return }
                            currentIndex = min(lastIndex, currentIndex + 1)
                        }
                        .appProminentButtonStyle(tint: Theme.primary)
                        .disabled(currentIndex >= cards.count - 1)
                    }
                } else {
                    Text("No approved cards yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .frame(maxWidth: 520)
            .appGlassCard(cornerRadius: 20)
            .padding(.horizontal, 24)
        }
        .navigationTitle("Practice")
        .onChange(of: cards.count) { _, _ in
            if cards.isEmpty {
                currentIndex = 0
            } else if currentIndex > lastIndex {
                currentIndex = lastIndex
            }
        }
    }
}

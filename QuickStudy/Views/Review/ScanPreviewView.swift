//
//  ScanPreviewView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

/// Walks every drafted card against the page it came from, with that card's lines
/// highlighted, so the card-to-source link is proved before the user reviews drafts.
struct ScanPreviewView: View {
    let draft: DraftSet
    let onContinue: () -> Void
    let onCancel: () -> Void

    @State private var cardIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Text(pageLabel)
                    .font(.headline)
                Spacer()
                Button("Skip", action: onContinue)
                    .fontWeight(.semibold)
            }

            ScrollView {
                SourcePageView(
                    lines: Array(draft.document.lines[pageRange]),
                    highlighted: currentCard?.source?.lineRange,
                    lineOffset: pageRange.lowerBound
                )
                .padding(Spacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appGlassCard(cornerRadius: AppRadius.lg)
            }

            TabView(selection: $cardIndex) {
                ForEach(Array(draft.cards.enumerated()), id: \.element.id) { index, card in
                    DraftedCardPreview(card: card, position: index + 1, total: draft.cards.count)
                        .padding(.bottom, Spacing.lg)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: draft.cards.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 190)
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
    }

    private var currentCard: StudyCard? {
        draft.cards.indices.contains(cardIndex) ? draft.cards[cardIndex] : draft.cards.first
    }

    private var pageLabel: String {
        draft.pageCount == 1 ? "1 page" : "Page \(pageIndex + 1) of \(draft.pageCount)"
    }

    /// The page follows the selected card rather than the other way round, so paging is
    /// a consequence of moving through cards instead of a second thing to navigate.
    private var pageIndex: Int {
        guard let range = currentCard?.source?.lineRange,
              let breaks = draft.document.pageBreaks,
              case let line = range.lowerBound,
              let index = breaks.lastIndex(where: { $0 <= line }) else { return 0 }
        return index
    }

    private var pageRange: ClosedRange<Int> {
        let breaks = draft.document.pageBreaks ?? [0]
        let start = breaks.indices.contains(pageIndex) ? breaks[pageIndex] : 0
        let end = breaks.indices.contains(pageIndex + 1) ? breaks[pageIndex + 1] - 1 : draft.document.lines.count - 1
        return start...max(start, end)
    }
}

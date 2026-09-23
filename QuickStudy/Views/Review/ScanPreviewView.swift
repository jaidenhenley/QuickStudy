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
    @State private var showDiscardAlert = false
    @ScaledMetric(relativeTo: .body) private var tabHeight: CGFloat = 228

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            HStack {
                Button("Cancel") { showDiscardAlert = true }
                Spacer()
                Text(pageLabel)
                    .font(.headline)
                Spacer()
                Button(reviewLabel, action: onContinue)
                    .fontWeight(.semibold)
            }

            // Glass belongs on the scroll view, not its content: inside, the scroll view
            // clips the card's rounded corners flat as soon as the text overflows.
            ScrollView {
                SourcePageView(
                    lines: Array(draft.document.lines[pageRange]),
                    highlighted: currentCard?.source?.lineRange,
                    lineOffset: pageRange.lowerBound
                )
                .padding(Spacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .appGlassCard(cornerRadius: AppRadius.lg)

            TabView(selection: $cardIndex) {
                ForEach(Array(draft.cards.enumerated()), id: \.element.id) { index, card in
                    DraftedCardPreview(
                        card: card,
                        position: index + 1,
                        cardCount: draft.cards.count,
                        pageIndex: index,
                        pageCount: pageTotal
                    )
                    .padding(.bottom, Spacing.xs)
                    .tag(index)
                }

                DraftedDeckSummary(
                    cardCount: draft.cards.count,
                    pageIndex: draft.cards.count,
                    pageCount: pageTotal,
                    onReview: onContinue
                )
                .padding(.bottom, Spacing.xs)
                .tag(draft.cards.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: tabHeight)
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
        .alert("Discard draft?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive, action: onCancel)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("The \(draft.cards.count) drafted \(cardNoun) will be deleted. This used one of your free generations.")
        }
    }

    private var cardNoun: String {
        draft.cards.count == 1 ? "card" : "cards"
    }

    private var pageTotal: Int { draft.cards.count + 1 }

    private var reviewLabel: String {
        draft.cards.count == 1 ? "Review 1 card" : "Review \(draft.cards.count) cards"
    }

    /// The closing page holds the last card's highlight so the source doesn't blank out.
    private var currentCard: StudyCard? {
        if draft.cards.indices.contains(cardIndex) { return draft.cards[cardIndex] }
        return draft.cards.last
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

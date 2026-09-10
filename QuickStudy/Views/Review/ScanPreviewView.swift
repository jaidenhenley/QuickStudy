//
//  ScanPreviewView.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 9/10/26.
//

import SwiftUI

/// Shows each page of the source with the paragraph a card came from highlighted,
/// so the card-to-source link is proved before the user invests in reviewing drafts.
struct ScanPreviewView: View {
    let draft: DraftSet
    let onContinue: () -> Void
    let onCancel: () -> Void

    @State private var pageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.base) {
            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Text("\(pageIndex + 1) of \(pageCount) \(pageCount == 1 ? "page" : "pages")")
                    .font(.headline)
                Spacer()
                Button(pageIndex + 1 < pageCount ? "Next" : "Review") {
                    if pageIndex + 1 < pageCount {
                        pageIndex += 1
                    } else {
                        onContinue()
                    }
                }
                .fontWeight(.semibold)
            }

            ScrollView {
                SourcePageView(
                    lines: Array(draft.document.lines[pageRange]),
                    highlighted: featuredCard?.source?.lineRange,
                    lineOffset: pageRange.lowerBound
                )
                .padding(Spacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
                .appGlassCard(cornerRadius: AppRadius.lg)
            }

            if let card = featuredCard, let position = cardPosition(of: card) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "sparkles")
                        Text("CARD \(position) OF \(draft.cards.count) · DRAFTED")
                            .tracking(0.5)
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPrimary)

                    Text(card.question)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(card.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.base)
                .appGlassCard(cornerRadius: AppRadius.lg, tint: Color.appPrimary.opacity(0.2))
            }
        }
        .padding(Spacing.lg)
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
    }

    private var pageCount: Int { draft.pageCount }

    private var pageRange: ClosedRange<Int> {
        let breaks = draft.document.pageBreaks ?? [0]
        let start = breaks.indices.contains(pageIndex) ? breaks[pageIndex] : 0
        let end = breaks.indices.contains(pageIndex + 1) ? breaks[pageIndex + 1] - 1 : draft.document.lines.count - 1
        return start...max(start, end)
    }

    /// The first card sourced to this page — the one whose origin gets highlighted.
    private var featuredCard: StudyCard? {
        draft.cards.first { card in
            guard let range = card.source?.lineRange else { return false }
            return pageRange.contains(range.lowerBound)
        } ?? draft.cards.first
    }

    private func cardPosition(of card: StudyCard) -> Int? {
        draft.cards.firstIndex(where: { $0.id == card.id }).map { $0 + 1 }
    }
}

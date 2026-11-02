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
    @State private var scrolledLine: Int?
    @ScaledMetric(relativeTo: .body) private var tabHeight: CGFloat = 228
    @ScaledMetric(relativeTo: .body) private var sourceMinHeight: CGFloat = 140
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.base) {
                    let headerLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.xs))
                        : AnyLayout(HStackLayout())

                    headerLayout {
                        Button("Cancel") { showDiscardAlert = true }
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        Text(pageLabel)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                        Button(reviewLabel, action: onContinue)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
                    }

                    // Glass belongs on the scroll view, not its content: inside, the scroll view
                    // clips the card's rounded corners flat as soon as the text overflows.
                    ScrollView {
                        SourcePageView(
                            lines: Array(draft.document.lines[pageRange]),
                            highlighted: currentCard?.source?.lineRange,
                            lineOffset: pageRange.lowerBound
                        )
                        // Lines are identified by their Int index; a bare Int page id collided
                        // with line 0 and scrolled the whole page instead of the line.
                        .id("page-\(pageIndex)")
                        // The outgoing page leaves at once: crossfading two pages of text
                        // stacks both legibly on top of each other.
                        .appTransition(.asymmetric(insertion: .opacity, removal: .identity))
                        .padding(Spacing.base)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: sourceMinHeight)
                    .scrollPosition(id: $scrolledLine, anchor: .center)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    .appGlassCard(cornerRadius: AppRadius.lg)
                    .appAnimation(Motion.standard, value: cardIndex)
                    .onAppear { scrolledLine = highlightAnchorLine }
                    .onChange(of: cardIndex) {
                        withAnimation(reduceMotion ? Motion.crossfade : Motion.standard) {
                            scrolledLine = highlightAnchorLine
                        }
                    }

                    TabView(selection: $cardIndex) {
                        ForEach(Array(draft.cards.enumerated()), id: \.element.id) { index, card in
                            DraftedCardPreview(
                                card: card,
                                position: index + 1,
                                cardCount: draft.cards.count,
                                pageIndex: index,
                                pageCount: pageTotal,
                                onAdjust: page
                            )
                            .padding(.bottom, Spacing.xs)
                            .tag(index)
                        }

                        DraftedDeckSummary(
                            cardCount: draft.cards.count,
                            pageIndex: draft.cards.count,
                            pageCount: pageTotal,
                            onReview: onContinue,
                            onAdjust: page
                        )
                        .padding(.bottom, Spacing.xs)
                        .tag(draft.cards.count)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .sensoryFeedback(.impact(weight: .light), trigger: cardIndex)
                    .frame(height: pagerHeight)
                }
                .padding(Spacing.lg)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(BackgroundView())
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .tabBar)
        .alert("Discard draft?", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive, action: onCancel)
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text(draft.discardWarning)
        }
    }

    private var pagerHeight: CGFloat {
        verticalSizeClass == .compact ? 150 : min(tabHeight, 360)
    }

    private func page(_ direction: AccessibilityAdjustmentDirection) {
        let target: Int
        switch direction {
        case .increment: target = min(cardIndex + 1, draft.cards.count)
        case .decrement: target = max(cardIndex - 1, 0)
        @unknown default: return
        }
        withAnimation(reduceMotion ? Motion.crossfade : Motion.standard) { cardIndex = target }
        AccessibilityNotification.Announcement(pagerAnnouncement).post()
    }

    private var pagerAnnouncement: String {
        if cardIndex < draft.cards.count {
            return "Card \(cardIndex + 1) of \(draft.cards.count)"
        }
        return draft.cards.count == 1 ? "That's the only card" : "That's all \(draft.cards.count) cards"
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

    /// The middle of the card's lines, kept on the visible page, so a long source range is
    /// centred rather than pinned by its first line.
    private var highlightAnchorLine: Int {
        guard let range = currentCard?.source?.lineRange else { return pageRange.lowerBound }
        let middle = (range.lowerBound + range.upperBound) / 2
        return min(max(middle, pageRange.lowerBound), pageRange.upperBound)
    }

    private var pageRange: ClosedRange<Int> {
        let breaks = draft.document.pageBreaks ?? [0]
        let start = breaks.indices.contains(pageIndex) ? breaks[pageIndex] : 0
        let end = breaks.indices.contains(pageIndex + 1) ? breaks[pageIndex + 1] - 1 : draft.document.lines.count - 1
        return start...max(start, end)
    }
}

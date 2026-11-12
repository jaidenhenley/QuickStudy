//
//  CardSourceSheet.swift
//  QuickStudy
//

import SwiftUI

struct CardSourceSheet: View {
    private let source: CardSource
    private let document: StudyDocument
    private let passage: Passage

    @State private var showsFullPage = false
    @State private var scrolledLine: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init?(card: StudyCard, document: StudyDocument) {
        guard let source = card.source,
              let passage = Passage(source: source, document: document) else { return nil }
        self.source = source
        self.document = document
        self.passage = passage
    }

    static func canShow(_ card: StudyCard, in document: StudyDocument) -> Bool {
        guard let source = card.source else { return false }
        return Passage(source: source, document: document) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if showsFullPage, let page = passage.page {
                        SourcePageView(
                            lines: Array(document.lines[page]),
                            highlighted: passage.highlighted,
                            lineOffset: page.lowerBound
                        )
                        // Set once the page's lines exist, or the scroll target can't resolve.
                        .onAppear { scrolledLine = passage.anchorLine }
                    } else {
                        SourcePageView(
                            lines: passage.lines,
                            highlighted: passage.highlighted,
                            lineOffset: passage.lineOffset
                        )
                        .onAppear { scrolledLine = passage.lineOffset }
                    }
                }
                .padding(Spacing.base)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .padding(.horizontal, Spacing.base)
                .padding(.top, Spacing.sm)
            }
            .scrollPosition(id: $scrolledLine, anchor: .center)
            .scrollBounceBehavior(.basedOnSize)
            .background(BackgroundView())
            .navigationTitle(source.page.map { String(localized: "Source · Page \($0)") } ?? String(localized: "Source"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if passage.page != nil {
                    Button {
                        withAnimation(reduceMotion ? Motion.crossfade : Motion.standard) {
                            showsFullPage.toggle()
                        }
                    } label: {
                        Text(showsFullPage ? String(localized: "Show Passage") : String(localized: "Show Full Page"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Theme.primary)
                            .padding(.horizontal, Spacing.base)
                            .frame(minHeight: 44)
                            .background(Theme.primary.opacity(0.12), in: .capsule)
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

extension CardSourceSheet {
    /// The card's lines with up to two non-empty lines of context either side, kept on the
    /// card's page. A missing or stale line range falls back to the stored excerpt.
    struct Passage {
        let lines: [String]
        let lineOffset: Int
        let highlighted: ClosedRange<Int>
        let page: ClosedRange<Int>?

        private static let contextLineCount = 2

        var anchorLine: Int {
            let middle = (highlighted.lowerBound + highlighted.upperBound) / 2
            guard let page else { return middle }
            return min(max(middle, page.lowerBound), page.upperBound)
        }

        init?(source: CardSource, document: StudyDocument) {
            let all = document.lines
            if let range = source.lineRange, all.indices.contains(range.lowerBound) {
                let lower = range.lowerBound
                let upper = min(max(range.upperBound, lower), all.count - 1)
                let page = Self.pageRange(containing: lower, in: document)
                let start = Self.contextBoundary(from: lower, step: -1, limit: page.lowerBound, in: all)
                let end = Self.contextBoundary(from: upper, step: 1, limit: max(page.upperBound, upper), in: all)
                lines = Array(all[start...end])
                lineOffset = start
                highlighted = lower...upper
                self.page = page
                return
            }
            let excerpt = source.excerpt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !excerpt.isEmpty else { return nil }
            lines = [excerpt]
            lineOffset = 0
            highlighted = 0...0
            page = nil
        }

        private static func pageRange(containing line: Int, in document: StudyDocument) -> ClosedRange<Int> {
            let lastLine = document.lines.count - 1
            guard let breaks = document.pageBreaks,
                  let index = breaks.lastIndex(where: { $0 <= line }) else { return 0...lastLine }
            let start = breaks[index]
            let end = breaks.indices.contains(index + 1) ? breaks[index + 1] - 1 : lastLine
            return start...min(max(start, end), lastLine)
        }

        private static func contextBoundary(from line: Int, step: Int, limit: Int, in lines: [String]) -> Int {
            var boundary = line
            var found = 0
            var index = line + step
            while found < contextLineCount, step < 0 ? index >= limit : index <= limit {
                if !lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                    boundary = index
                    found += 1
                }
                index += step
            }
            return boundary
        }
    }
}

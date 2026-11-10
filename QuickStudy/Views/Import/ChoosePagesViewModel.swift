//
//  ChoosePagesViewModel.swift
//  QuickStudy
//

import PDFKit
import UIKit

@Observable
@MainActor
final class ChoosePagesViewModel {
    static let pageLimit = 10
    // On-device engines expect 6 s per section (OnDeviceCardGenerationEngine.expectedSeconds); a page of notes is treated as one section.
    private static let secondsPerPage = 6.0

    let fileName: String
    let pageCount: Int
    private(set) var selection: Set<Int>
    private(set) var capWarningCount = 0
    private(set) var showsCapNote = false

    private let renderer: ThumbnailRenderer
    private var thumbnails: [Int: UIImage] = [:]
    private var capNoteTask: Task<Void, Never>?

    init(fileName: String, document: PDFDocument) {
        self.fileName = fileName
        self.pageCount = document.pageCount
        self.selection = Set(0..<min(document.pageCount, Self.pageLimit))
        self.renderer = ThumbnailRenderer(document: document)
    }

    var subtitle: String {
        "\(fileName) · \(pageCount) \(pageCount == 1 ? "page" : "pages")"
    }

    var sortedSelection: [Int] { selection.sorted() }

    var canDraft: Bool { !selection.isEmpty }

    var summary: String {
        let pages = sortedSelection
        guard let first = pages.first, let last = pages.last else { return "No pages selected" }
        if pages.count > 1, last - first + 1 == pages.count {
            return "Pages \(first + 1) to \(last + 1) selected"
        }
        return "\(pages.count) \(pages.count == 1 ? "page" : "pages") selected"
    }

    var estimate: String {
        let count = selection.count
        let seconds = Double(count) * Self.secondsPerPage
        let duration: String
        if seconds < 60 {
            duration = "\(Int(seconds.rounded())) seconds"
        } else {
            let minutes = Int((seconds / 60).rounded(.up))
            duration = "\(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }
        return "\(count) \(count == 1 ? "page" : "pages") · about \(duration) on this iPhone"
    }

    var buttonTitle: String {
        selection.count == 1 ? "Draft 1 Page" : "Draft \(selection.count) Pages"
    }

    func isSelected(_ index: Int) -> Bool { selection.contains(index) }

    func toggle(_ index: Int) {
        if selection.contains(index) {
            selection.remove(index)
        } else if selection.count >= Self.pageLimit {
            warnAboutLimit()
        } else {
            selection.insert(index)
        }
    }

    func thumbnail(at index: Int) async -> UIImage? {
        if let cached = thumbnails[index] { return cached }
        guard let image = await renderer.render(pageAt: index) else { return nil }
        thumbnails[index] = image
        return image
    }

    private func warnAboutLimit() {
        capWarningCount += 1
        showsCapNote = true
        capNoteTask?.cancel()
        capNoteTask = Task {
            try? await Task.sleep(for: .seconds(2.5)) // Cancelled on re-warn; the next note owns the timer.
            guard !Task.isCancelled else { return }
            showsCapNote = false
        }
    }
}

private actor ThumbnailRenderer {
    private struct DocumentBox: @unchecked Sendable { let document: PDFDocument }

    private let box: DocumentBox
    private static let size = CGSize(width: 240, height: 320)

    init(document: PDFDocument) {
        box = DocumentBox(document: document)
    }

    func render(pageAt index: Int) -> UIImage? {
        box.document.page(at: index)?.thumbnail(of: Self.size, for: .cropBox)
    }
}

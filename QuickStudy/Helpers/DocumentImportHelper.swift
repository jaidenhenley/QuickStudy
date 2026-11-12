//
//  DocumentImportHelper.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import CoreImage
import ImageIO
import PDFKit
import UIKit
import Vision

nonisolated enum DocumentImportError: Error {
    case unreadablePDF
}

// MARK: - Document import helper

/// Progress callbacks run on the main actor between pages, so a page count can never
/// land after the caller has moved on to drafting. Vision, PDFKit and page rendering
/// run off the main actor.
struct DocumentImportHelper {
    let isHandwritingMode: Bool
    let isUltraHandwritingMode: Bool

    // MARK: Public API

    func extractText(
        from images: [UIImage],
        onPageComplete: (Int, Int) -> Void = { _, _ in }
    ) async throws -> ExtractedDocument {
        var pages: [ExtractedDocument.Page] = []
        for index in images.indices {
            try Task.checkCancellation()
            let candidates = await ocrLines(for: images[index])
            let lines = candidates.map { $0.first ?? "" }
            pages.append(
                ExtractedDocument.Page(
                    text: lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines),
                    candidates: candidates
                )
            )
            onPageComplete(index + 1, images.count)
        }
        return ExtractedDocument(pages: pages)
    }

    func extractText(
        from pdfURL: URL,
        onPageComplete: (Int, Int) -> Void = { _, _ in }
    ) async throws -> ExtractedDocument {
        let document = try await openPDF(at: pdfURL)
        return try await extractText(from: document, onPageComplete: onPageComplete)
    }

    /// Reads the whole file up front, so the document stays usable after the
    /// security-scoped access to a Files URL ends.
    func openPDF(at url: URL) async throws -> PDFDocument {
        try await Self.loadPDF(at: url)
    }

    /// `pageIndices` limits the read to those zero-based pages. Pages before the last
    /// chosen one that weren't chosen come back empty, so each page keeps its real number
    /// in `pageBreaks` and a card's source still names the page the user saw.
    func extractText(
        from document: PDFDocument,
        pageIndices: [Int]? = nil,
        onPageComplete: (Int, Int) -> Void = { _, _ in }
    ) async throws -> ExtractedDocument {
        let chosen = Set(pageIndices ?? Array(0..<document.pageCount))
            .filter { (0..<document.pageCount).contains($0) }
            .sorted()
        let content = await Self.readPDF(
            document,
            pageIndices: chosen,
            prefersEmbeddedText: !isHandwritingMode,
            renderScale: isUltraHandwritingMode ? 3.0 : 2.5,
            maxDimension: isUltraHandwritingMode ? 2200 : nil
        )
        let chosenPages: [ExtractedDocument.Page]
        switch content {
        case let .embeddedText(pageTexts):
            onPageComplete(pageTexts.count, pageTexts.count)
            chosenPages = pageTexts.map { ExtractedDocument.Page(text: $0, candidates: []) }
        case let .renderedPages(images):
            chosenPages = try await extractText(from: images, onPageComplete: onPageComplete).pages
        }
        guard let lastIndex = chosen.last else { return ExtractedDocument(pages: []) }
        let pagesByIndex = Dictionary(uniqueKeysWithValues: zip(chosen, chosenPages))
        return ExtractedDocument(pages: (0...lastIndex).map { index in
            pagesByIndex[index] ?? ExtractedDocument.Page(text: "", candidates: [])
        })
    }

    // MARK: OCR

    private func ocrLines(for image: UIImage) async -> [[String]] {
        do {
            return try await Self.recognizeLines(
                in: image,
                mode: isHandwritingMode ? .handwritingBoost : .none,
                handwritingMode: isHandwritingMode,
                candidateCount: 5,
                ultraMode: isHandwritingMode && isUltraHandwritingMode
            )
        } catch {
            // A page Vision can't read counts as blank so the rest of the document still
            // imports. A document with no readable page surfaces as "No text was detected".
            return []
        }
    }

    @concurrent
    nonisolated private static func recognizeLines(
        in image: UIImage,
        mode: PreprocessMode,
        handwritingMode: Bool,
        candidateCount: Int,
        ultraMode: Bool
    ) async throws -> [[String]] {
        guard let cgImage = preprocessImage(image, mode: mode) ?? image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.revision = VNRecognizeTextRequestRevision3
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = recognitionLanguages(for: request)
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = handwritingMode
            ? (ultraMode ? 0.015 : 0.02)
            : 0.012

        let handler = VNImageRequestHandler(
            cgImage: cgImage,
            orientation: CGImagePropertyOrientation(image.imageOrientation),
            options: [:]
        )
        try handler.perform([request])

        let sorted = (request.results ?? []).sorted { lhs, rhs in
            let lhsY = lhs.boundingBox.midY
            let rhsY = rhs.boundingBox.midY
            if abs(lhsY - rhsY) > 0.01 {
                return lhsY > rhsY
            }
            return lhs.boundingBox.minX < rhs.boundingBox.minX
        }
        return sorted.map { observation in
            observation.topCandidates(candidateCount).map { $0.string }
        }
    }

    // MARK: PDF helpers

    /// Pages are often in a language other than the iPhone's, so detection stays on and the
    /// reader's preferred languages are passed as hints, with English always included.
    nonisolated private static func recognitionLanguages(for request: VNRecognizeTextRequest) -> [String] {
        let fallback = "en-US"
        // A revision that cannot list its languages still reads English, which matches the
        // behaviour before multilingual import, so the failure needs no further handling.
        let supported = (try? request.supportedRecognitionLanguages()) ?? [fallback]
        let preferred = Locale.preferredLanguages.compactMap { identifier -> String? in
            let code = Locale(identifier: identifier).language.languageCode
            return supported.first { Locale(identifier: $0).language.languageCode == code }
        }
        var languages: [String] = []
        for language in preferred + [fallback] where !languages.contains(language) {
            languages.append(language)
        }
        return languages
    }

    private nonisolated enum PDFContent {
        case embeddedText([String])
        case renderedPages([UIImage])
    }

    @concurrent
    nonisolated private static func loadPDF(at url: URL) async throws -> PDFDocument {
        let accessGranted = url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        guard let document = PDFDocument(data: data), !document.isLocked else {
            throw DocumentImportError.unreadablePDF
        }
        return document
    }

    @concurrent
    nonisolated private static func readPDF(
        _ document: PDFDocument,
        pageIndices: [Int],
        prefersEmbeddedText: Bool,
        renderScale: CGFloat,
        maxDimension: CGFloat?
    ) async -> PDFContent {
        if prefersEmbeddedText {
            let pageTexts = pageIndices.map { index in
                document.page(at: index)?.string?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            if pageTexts.joined(separator: "\n").count >= 40 {
                return .embeddedText(pageTexts)
            }
        }

        let images = renderPages(pageIndices, of: document, scale: renderScale)
        guard let maxDimension else { return .renderedPages(images) }
        return .renderedPages(scaleImages(images, maxDimension: maxDimension))
    }

    /// A page PDFKit can't return renders blank, so the images stay aligned with
    /// `pageIndices`.
    nonisolated private static func renderPages(_ pageIndices: [Int], of document: PDFDocument, scale: CGFloat) -> [UIImage] {
        pageIndices.map { pageIndex in
            guard let page = document.page(at: pageIndex) else { return UIImage() }
            let pageRect = page.bounds(for: .mediaBox)
            let targetSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))

                context.cgContext.saveGState()
                context.cgContext.scaleBy(x: scale, y: scale)
                context.cgContext.translateBy(x: 0, y: pageRect.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
        }
    }

    nonisolated private static func scaleImages(_ images: [UIImage], maxDimension: CGFloat) -> [UIImage] {
        images.map { image in
            let size = image.size
            let maxSide = max(size.width, size.height)
            guard maxSide > maxDimension else { return image }
            let scale = maxDimension / maxSide
            let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }
    }

    // MARK: Image preprocessing

    nonisolated enum PreprocessMode {
        case none
        case handwritingBoost
    }

    nonisolated static func preprocessImage(_ image: UIImage, mode: PreprocessMode) -> CGImage? {
        switch mode {
        case .none:
            return image.cgImage
        case .handwritingBoost:
            return preprocessForHandwritingBoost(image)
        }
    }

    nonisolated static func preprocessForHandwritingBoost(_ image: UIImage) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        let controls = ciImage.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: 0.0,
                kCIInputContrastKey: 1.45,
                kCIInputBrightnessKey: 0.05
            ]
        )

        let exposure = controls.applyingFilter(
            "CIExposureAdjust",
            parameters: [
                kCIInputEVKey: 0.9
            ]
        )

        let sharpened = exposure.applyingFilter(
            "CIUnsharpMask",
            parameters: [
                kCIInputRadiusKey: 2.0,
                kCIInputIntensityKey: 0.85
            ]
        )

        let context = CIContext(options: nil)
        return context.createCGImage(sharpened, from: sharpened.extent)
    }

}
private extension CGImagePropertyOrientation {
    nonisolated init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .down: self = .down
        case .left: self = .left
        case .right: self = .right
        case .upMirrored: self = .upMirrored
        case .downMirrored: self = .downMirrored
        case .leftMirrored: self = .leftMirrored
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}

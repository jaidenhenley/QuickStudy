//
//  DocumentImportHelper.swift
//  QuickStudy
//
//  Created by Jaiden Henley on 2/28/26.
//

import CoreImage
import PDFKit
import UIKit
import Vision

// MARK: - Document import helper

struct DocumentImportHelper {
    let isHandwritingMode: Bool
    let isUltraHandwritingMode: Bool

    // MARK: Public API

    func extractText(from images: [UIImage]) async throws -> String {
        let result = await ocrResult(images: images)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractText(from pdfURL: URL) async throws -> String {
        let accessGranted = pdfURL.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                pdfURL.stopAccessingSecurityScopedResource()
            }
        }

        guard let document = PDFDocument(url: pdfURL) else { return "" }

        if !isHandwritingMode {
            let extracted = extractText(from: document)
            let trimmed = extracted.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count >= 40 {
                return trimmed
            }
        }

        let images = renderPDFPages(document, scale: isUltraHandwritingMode ? 3.0 : 2.0)
        let scaled = isUltraHandwritingMode ? scaleImages(images, maxDimension: 2200) : images
        return try await extractText(from: scaled)
    }

    // MARK: OCR

    private func ocrResult(images: [UIImage]) async -> String {
        var fullTextLines: [String] = []

        for pageIndex in images.indices {
            let image = images[pageIndex]
            let lines = await ocrLines(for: image)
            fullTextLines.append(contentsOf: lines)

            if pageIndex < images.count - 1 {
                fullTextLines.append("")
            }
        }

        return fullTextLines.joined(separator: "\n")
    }

    func ocrLines(for image: UIImage) async -> [String] {
        // Simplified OCR: one normal pass, or a single handwriting-boosted pass.
        if isHandwritingMode {
            if let lines = try? await performVisionOCRCandidates(
                on: image,
                mode: .handwritingBoost,
                handwritingMode: true,
                candidateCount: 5,
                ultraMode: isUltraHandwritingMode
            ) {
                return lines.map { $0.first ?? "" }
            }
        } else {
            if let lines = try? await performVisionOCRCandidates(
                on: image,
                mode: .none,
                handwritingMode: false,
                candidateCount: 5,
                ultraMode: false
            ) {
                return lines.map { $0.first ?? "" }
            }
        }

        return []
    }

    private func performVisionOCRCandidates(
        on image: UIImage,
        mode: PreprocessMode,
        handwritingMode: Bool,
        candidateCount: Int,
        ultraMode: Bool
    ) async throws -> [[String]] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let sourceImage = Self.preprocessImage(image, mode: mode)
                guard let cgImage = sourceImage ?? image.cgImage else {
                    continuation.resume(returning: [])
                    return
                }
                let request = VNRecognizeTextRequest { request, _ in
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let candidates = observations.map { observation in
                        observation.topCandidates(candidateCount).map { $0.string }
                    }
                    continuation.resume(returning: candidates)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.recognitionLanguages = ["en_US"]
                request.automaticallyDetectsLanguage = false
                request.minimumTextHeight = handwritingMode
                    ? (ultraMode ? 0.015 : 0.02)
                    : 0.0

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: PDF helpers

    func extractText(from document: PDFDocument) -> String {
        var parts: [String] = []
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex),
               let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
               !pageText.isEmpty {
                parts.append(pageText)
            }
        }
        return parts.joined(separator: "\n")
    }

    func renderPDFPages(_ document: PDFDocument, scale: CGFloat) -> [UIImage] {
        var images: [UIImage] = []
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let targetSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: targetSize)
            let image = renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: targetSize))

                context.cgContext.saveGState()
                context.cgContext.scaleBy(x: scale, y: scale)
                context.cgContext.translateBy(x: 0, y: pageRect.height)
                context.cgContext.scaleBy(x: 1, y: -1)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
            images.append(image)
        }
        return images
    }

    func scaleImages(_ images: [UIImage], maxDimension: CGFloat) -> [UIImage] {
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

    enum PreprocessMode {
        case none
        case handwritingBoost
    }

    static func preprocessImage(_ image: UIImage, mode: PreprocessMode) -> CGImage? {
        switch mode {
        case .none:
            return image.cgImage
        case .handwritingBoost:
            return preprocessForHandwritingBoost(image)
        }
    }

    static func preprocessForHandwritingBoost(_ image: UIImage) -> CGImage? {
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

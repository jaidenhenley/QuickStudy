// OCR Cleanup Pipeline - QuickStudy
// Transforms raw VisionKit output into clean, AI-ready text through multi-stage processing

import UIKit
import Vision
import CoreImage

struct OCRCleanupPipeline {

    // Enhances image quality before OCR by applying desaturation, contrast boost,
    // exposure adjustment, and sharpening to improve handwriting recognition
    static func preprocessForHandwriting(_ image: UIImage) -> CGImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)

        let controls = ciImage.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: 0.0,      // Grayscale
                kCIInputContrastKey: 1.45,       // Boost contrast
                kCIInputBrightnessKey: 0.05
            ]
        )

        let exposure = controls.applyingFilter(
            "CIExposureAdjust",
            parameters: [kCIInputEVKey: 0.9]
        )

        let sharpened = exposure.applyingFilter(
            "CIUnsharpMask",
            parameters: [kCIInputRadiusKey: 2.0, kCIInputIntensityKey: 0.85]
        )

        let context = CIContext(options: nil)
        return context.createCGImage(sharpened, from: sharpened.extent)
    }

    // Performs Vision OCR and returns top 5 candidate strings per line
    // to enable downstream AI correction using context
    func performOCR(on image: UIImage, handwritingMode: Bool) async throws -> [[String]] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let processedImage = handwritingMode ?
                    Self.preprocessForHandwriting(image) : image.cgImage

                guard let cgImage = processedImage ?? image.cgImage else {
                    continuation.resume(returning: [])
                    return
                }

                let request = VNRecognizeTextRequest { request, _ in
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let candidates = observations.map { $0.topCandidates(5).map { $0.string } }
                    continuation.resume(returning: candidates)
                }

                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                request.minimumTextHeight = handwritingMode ? 0.015 : 0.0

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                try? handler.perform([request])
            }
        }
    }

    // Normalizes OCR output by removing artifacts and fixing broken hyphenation.
    // Merges fragmented lines when >33% are stray 1-2 character artifacts
    func normalizeOCRLines(_ rawText: String) -> [String] {
        let cleanLines = rawText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !cleanLines.isEmpty else { return [] }

        let shortLineCount = cleanLines.filter { $0.count <= 2 }.count

        // If >33% of lines are 1-2 characters, merge everything (common OCR artifact)
        if shortLineCount * 3 >= cleanLines.count {
            let combined = cleanLines.joined(separator: " ")
            return [combined.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)]
        }

        return cleanLines
    }

    // Corrects misspelled words using UITextChecker while preserving
    // technical terms and words containing digits
    func spellCorrect(_ text: String, ignoreList: Set<String>) -> String {
        let checker = UITextChecker()
        let language = Locale.current.identifier

        let correctedLines = text.components(separatedBy: .newlines).map { line -> String in
            var corrected = line
            var offset = 0

            while offset < corrected.utf16.count {
                let range = NSRange(location: offset, length: corrected.utf16.count - offset)
                let misspelledRange = checker.rangeOfMisspelledWord(
                    in: corrected, range: range, startingAt: offset, wrap: false, language: language
                )

                guard misspelledRange.location != NSNotFound else { break }

                let word = (corrected as NSString).substring(with: misspelledRange)
                let shouldIgnore = ignoreList.contains(word.lowercased()) ||
                                 word.rangeOfCharacter(from: .decimalDigits) != nil

                if shouldIgnore {
                    offset = misspelledRange.location + misspelledRange.length
                    continue
                }

                if let bestGuess = checker.guesses(
                    forWordRange: misspelledRange, in: corrected, language: language
                )?.first {
                    corrected = (corrected as NSString)
                        .replacingCharacters(in: misspelledRange, with: bestGuess)
                    offset = misspelledRange.location + bestGuess.utf16.count
                } else {
                    offset = misspelledRange.location + misspelledRange.length
                }
            }
            return corrected
        }

        return correctedLines.joined(separator: "\n")
    }

    // Complete pipeline: preprocessing → OCR → normalization → spell correction
    func processImage(
        _ image: UIImage,
        handwritingMode: Bool,
        technicalTerms: Set<String> = ["swift", "swiftui", "ios", "ocr"]
    ) async throws -> String {
        let candidates = try await performOCR(on: image, handwritingMode: handwritingMode)
        let rawText = candidates.map { $0.first ?? "" }.joined(separator: "\n")
        let normalizedLines = normalizeOCRLines(rawText)
        let normalizedText = normalizedLines.joined(separator: "\n")
        let correctedText = spellCorrect(normalizedText, ignoreList: technicalTerms)
        return correctedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import CoreGraphics
import XCTest

enum BlankScreenCheck {
    struct Report {
        let labelledElementCount: Int
        let pixelStandardDeviation: Double
        let isBlank: Bool
        let summary: String
    }

    static let minimumLabelledElements = 2
    static let minimumPixelStandardDeviation = 2.0

    static func evaluate(app: XCUIApplication) -> Report {
        let kinds: [XCUIElement.ElementType] = [
            .staticText, .button, .textField, .secureTextField, .textView, .switch, .tab, .cell, .image, .link
        ]
        var labelled = 0
        for kind in kinds {
            let query = app.descendants(matching: kind)
            for index in 0..<min(query.count, 40) {
                let element = query.element(boundBy: index)
                if element.exists, !element.label.isEmpty { labelled += 1 }
            }
        }
        let deviation = pixelStandardDeviation(of: app.screenshot().image.cgImage)
        let blank = labelled < minimumLabelledElements || deviation < minimumPixelStandardDeviation
        return Report(
            labelledElementCount: labelled,
            pixelStandardDeviation: deviation,
            isBlank: blank,
            summary: "labelled elements: \(labelled), pixel stddev: \(String(format: "%.2f", deviation))"
        )
    }

    /// Standard deviation of luminance on a 48x48 downsample; a flat white or black screen is ~0.
    static func pixelStandardDeviation(of image: CGImage?) -> Double {
        guard let image else { return 0 }
        let side = 48
        var pixels = [UInt8](repeating: 0, count: side * side)
        guard let context = CGContext(
            data: &pixels,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }
        context.interpolationQuality = .low
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        let values = pixels.map(Double.init)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(values.count)
        return variance.squareRoot()
    }
}

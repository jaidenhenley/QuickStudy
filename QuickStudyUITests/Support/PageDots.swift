import CoreGraphics
import XCTest

/// The onboarding page dots are not in the accessibility tree, so the active dot is found by colour.
enum PageDots {
    /// Horizontal centre (in points) of the elongated indigo dot in the strip above the home indicator, or nil.
    static func activeDotCenter(in app: XCUIApplication, band: ClosedRange<CGFloat> = 818...842) -> Double? {
        guard let image = app.screenshot().image.cgImage else { return nil }
        let scale = CGFloat(image.width) / app.frame.width
        let width = image.width
        let top = Int(band.lowerBound * scale)
        let bottom = Int(band.upperBound * scale)
        let rows = bottom - top
        guard rows > 0 else { return nil }
        var pixels = [UInt8](repeating: 0, count: width * rows * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: rows, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let slice = image.cropping(to: CGRect(x: 0, y: top, width: width, height: rows)) else { return nil }
        context.draw(slice, in: CGRect(x: 0, y: 0, width: width, height: rows))
        var sum = 0.0
        var count = 0.0
        for row in 0..<rows {
            for column in 0..<width {
                let offset = (row * width + column) * 4
                let r = Int(pixels[offset]), g = Int(pixels[offset + 1]), b = Int(pixels[offset + 2])
                if r < 130, g < 130, b > 170, b - r > 70 {
                    sum += Double(column)
                    count += 1
                }
            }
        }
        return count > 20 ? sum / count / Double(scale) : nil
    }
}

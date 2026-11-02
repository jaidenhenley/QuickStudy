import XCTest

enum Evidence {
    static var directory: URL {
        let path = ProcessInfo.processInfo.environment["QS_EVIDENCE_DIR"]
            ?? (NSTemporaryDirectory() as NSString).appendingPathComponent("qs-evidence")
        let url = URL(fileURLWithPath: path, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func fileName(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return name.unicodeScalars.map { allowed.contains($0) ? String($0) : "_" }.joined()
    }

    @discardableResult
    static func screenshot(_ name: String, app: XCUIApplication? = nil, in test: XCTestCase? = nil) -> URL? {
        let shot = app?.screenshot() ?? XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        test?.add(attachment)
        let url = directory.appendingPathComponent(fileName(name) + ".png")
        do {
            try shot.pngRepresentation.write(to: url)
            return url
        } catch {
            XCTFail("Could not write screenshot to \(url.path): \(error)")
            return nil
        }
    }

    @discardableResult
    static func hierarchy(_ name: String, app: XCUIApplication, in test: XCTestCase? = nil) -> URL? {
        let text = app.debugDescription
        let attachment = XCTAttachment(string: text)
        attachment.name = name + "-hierarchy"
        attachment.lifetime = .keepAlways
        test?.add(attachment)
        let url = directory.appendingPathComponent(fileName(name) + ".hierarchy.txt")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            XCTFail("Could not write hierarchy to \(url.path): \(error)")
            return nil
        }
    }
}

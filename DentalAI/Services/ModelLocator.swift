import Foundation

enum ModelLocator {
    static func modelExists(name: String, ext: String) -> Bool {
        return Bundle.main.url(forResource: name, withExtension: ext) != nil
    }

    /// True if ANY .mlmodelc exists in the app bundle (any name / subdir).
    static func anyCompiledMLExists() -> Bool {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil),
           !urls.isEmpty { return true }
        // Fallback deep scan (nested dirs)
        guard let root = Bundle.main.resourcePath else { return false }
        let fm = FileManager.default
        if let e = fm.enumerator(atPath: root) {
            for case let path as String in e {
                if path.hasSuffix(".mlmodelc") { return true }
            }
        }
        return false
    }
}

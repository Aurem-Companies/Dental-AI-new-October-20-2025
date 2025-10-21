// File: DentalAI/Services/ModelLocator.swift
import Foundation

enum ModelLocator {
    static func bundledURL(name: String, ext: String, subdir: String? = "models") -> URL? {
        if let subdir {
            return Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir)
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    static func modelExists(name: String, ext: String, subdir: String? = "models") -> Bool {
        bundledURL(name: name, ext: ext, subdir: subdir) != nil
    }
}

// Backwards-compatible helpers for compiled CoreML models
extension ModelLocator {
    static func bundledCompiledMLModelURL(name: String, subdir: String? = "models") -> URL? {
        bundledURL(name: name, ext: "mlmodelc", subdir: subdir)
    }
    static func hasCompiledMLModel(named name: String, subdir: String? = "models") -> Bool {
        modelExists(name: name, ext: "mlmodelc", subdir: subdir)
    }
    
    /// New: does *any* .mlmodelc exist in the app bundle?
    static func anyCompiledMLExists() -> Bool {
        if let urls = Bundle.main.urls(forResourcesWithExtension: "mlmodelc", subdirectory: nil) {
            return !urls.isEmpty
        }
        // Some projects place models in nested subdirectories; fallback to file enumeration:
        let fm = FileManager.default
        guard let resourcePath = Bundle.main.resourcePath else { return false }
        let enumerator = fm.enumerator(atPath: resourcePath)
        while let item = enumerator?.nextObject() as? String {
            if item.hasSuffix(".mlmodelc") { return true }
        }
        return false
    }
}

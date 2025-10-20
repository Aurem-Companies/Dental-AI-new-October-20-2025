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
}

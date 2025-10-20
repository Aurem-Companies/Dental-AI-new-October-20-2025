import Foundation

// MARK: - Model Locator Helper
struct ModelLocator {
    
    /// Safely locate a bundled model file
    /// - Parameters:
    ///   - name: The name of the model file (without extension)
    ///   - ext: The file extension (e.g., "mlmodel", "onnx", "pt")
    /// - Returns: URL to the bundled model file, or nil if not found
    static func bundledURL(name: String, ext: String) -> URL? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            #if DEBUG
            print("⚠️ Model not found in bundle: \(name).\(ext)")
            #endif
            return nil
        }
        
        #if DEBUG
        print("✅ Model found in bundle: \(name).\(ext)")
        #endif
        
        return url
    }
    
    /// Check if a model file exists in the bundle
    /// - Parameters:
    ///   - name: The name of the model file (without extension)
    ///   - ext: The file extension
    /// - Returns: true if the model exists in the bundle
    static func modelExists(name: String, ext: String) -> Bool {
        return bundledURL(name: name, ext: ext) != nil
    }
}

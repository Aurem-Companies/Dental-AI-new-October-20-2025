import Foundation

// MARK: - Feature Flags
struct FeatureFlags {
    
    // MARK: - ML Detection
    static var useMLDetection: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useMLDetection")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useMLDetection")
        }
    }
    
    // MARK: - CV Detection
    static var useCVDetection: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "useCVDetection")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "useCVDetection")
        }
    }
    
    // MARK: - Fallback Behavior
    static var enableFallback: Bool {
        get {
            return UserDefaults.standard.object(forKey: "enableFallback") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "enableFallback")
        }
    }
    
    // MARK: - Debug Mode
    static var debugMode: Bool {
        get {
            #if DEBUG
            return UserDefaults.standard.bool(forKey: "debugMode")
            #else
            return false
            #endif
        }
        set {
            #if DEBUG
            UserDefaults.standard.set(newValue, forKey: "debugMode")
            #endif
        }
    }
    
    // MARK: - Performance Settings
    static var highPerformanceMode: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "highPerformanceMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "highPerformanceMode")
        }
    }
    
    // MARK: - Model Settings
    static var modelConfidenceThreshold: Float {
        get {
            let threshold = UserDefaults.standard.float(forKey: "modelConfidenceThreshold")
            return threshold > 0 ? threshold : 0.5
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "modelConfidenceThreshold")
        }
    }
    
    // MARK: - Default Configuration
    static func configureDefaults() {
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: "useMLDetection") == nil {
            useMLDetection = true
        }
        
        if UserDefaults.standard.object(forKey: "useCVDetection") == nil {
            useCVDetection = true
        }
        
        if UserDefaults.standard.object(forKey: "enableFallback") == nil {
            enableFallback = true
        }
        
        if UserDefaults.standard.object(forKey: "modelConfidenceThreshold") == nil {
            modelConfidenceThreshold = 0.5
        }
    }
    
    // MARK: - Reset to Defaults
    static func resetToDefaults() {
        useMLDetection = true
        useCVDetection = true
        enableFallback = true
        debugMode = false
        highPerformanceMode = false
        modelConfidenceThreshold = 0.5
    }
    
    // MARK: - Feature Status
    static var featureStatus: String {
        var status = "Feature Flags Status:\n"
        status += "• ML Detection: \(useMLDetection ? "Enabled" : "Disabled")\n"
        status += "• CV Detection: \(useCVDetection ? "Enabled" : "Disabled")\n"
        status += "• Fallback: \(enableFallback ? "Enabled" : "Disabled")\n"
        status += "• Debug Mode: \(debugMode ? "Enabled" : "Disabled")\n"
        status += "• High Performance: \(highPerformanceMode ? "Enabled" : "Disabled")\n"
        status += "• Confidence Threshold: \(modelConfidenceThreshold)"
        return status
    }
}

// MARK: - Environment-based Configuration
extension FeatureFlags {
    
    // MARK: - Development Environment
    static var isDevelopment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Production Environment
    static var isProduction: Bool {
        #if DEBUG
        return false
        #else
        return true
        #endif
    }
    
    // MARK: - Environment-specific Defaults
    static func configureForEnvironment() {
        if isDevelopment {
            // Development defaults
            useMLDetection = true
            useCVDetection = true
            enableFallback = true
            debugMode = true
            highPerformanceMode = false
            modelConfidenceThreshold = 0.3
        } else {
            // Production defaults
            useMLDetection = true
            useCVDetection = true
            enableFallback = true
            debugMode = false
            highPerformanceMode = true
            modelConfidenceThreshold = 0.5
        }
    }
}

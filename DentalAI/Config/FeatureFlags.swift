import Foundation

struct FeatureFlags {
    var useONNXDetection: Bool
    var useMLDetection: Bool
    var useCVDetection: Bool
    var enableFallback: Bool
    var debugMode: Bool
    var highPerformanceMode: Bool
    var modelConfidenceThreshold: Double
}

extension FeatureFlags {
    static var current: FeatureFlags {
        let hasCompiledML = ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc")

        let flags = FeatureFlags(
            useONNXDetection: false,
            useMLDetection: hasCompiledML,   // auto-disable if model missing
            useCVDetection: true,
            enableFallback: true,
            debugMode: true,
            highPerformanceMode: false,
            modelConfidenceThreshold: 0.30
        )

        // Compile-time sanity (keeps API in sync if fields change)
        _ = { (f: FeatureFlags) in
            precondition(f.modelConfidenceThreshold >= 0 && f.modelConfidenceThreshold <= 1,
                         "FeatureFlags.modelConfidenceThreshold must be 0...1")
        }(flags)

        return flags
    }
}
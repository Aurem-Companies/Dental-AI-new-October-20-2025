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
        var flags = FeatureFlags(
            useONNXDetection: false,
            useMLDetection: hasCompiledML,
            useCVDetection: true,
            enableFallback: true,
            debugMode: true,
            highPerformanceMode: false,
            modelConfidenceThreshold: 0.30
        )

        FlagOverrides.apply(to: &flags)   // ← DEBUG-only no-op in Release

        _ = { (f: FeatureFlags) in
            precondition((0.0...1.0).contains(f.modelConfidenceThreshold),
                         "FeatureFlags.modelConfidenceThreshold must be 0...1")
        }(flags)

        return flags
    }
}
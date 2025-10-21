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
        let hasCompiledML = ModelLocator.anyCompiledMLExists()

        var flags = FeatureFlags(
            useONNXDetection: false,
            useMLDetection: hasCompiledML,   // auto-enable only if a .mlmodelc is truly bundled
            useCVDetection: true,
            enableFallback: true,
            debugMode: true,
            highPerformanceMode: false,
            modelConfidenceThreshold: 0.30
        )

        // Optional DEBUG overrides: if you implemented FlagOverrides.apply
        FlagOverrides.apply(to: &flags)

        precondition((0.0...1.0).contains(flags.modelConfidenceThreshold),
                     "FeatureFlags.modelConfidenceThreshold must be 0...1")
        return flags
    }
}
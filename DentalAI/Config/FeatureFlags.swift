import Foundation

struct FeatureFlags {
    var useONNXDetection: Bool
    var useMLDetection: Bool
    var useCVDetection: Bool
    var enableFallback: Bool
    var debugMode: Bool
    var highPerformanceMode: Bool
    var modelConfidenceThreshold: Double
    var enableYOLOPostProcessing: Bool   // NEW
}

extension FeatureFlags {
    static var current: FeatureFlags {
        let hasCompiledML = ModelLocator.anyCompiledMLExists()

        var flags = FeatureFlags(
            useONNXDetection: true,
            useMLDetection: hasCompiledML,   // default truth-based
            useCVDetection: true,
            enableFallback: true,
            debugMode: true,
            highPerformanceMode: false,
            modelConfidenceThreshold: 0.25,
            enableYOLOPostProcessing: false   // default OFF; flip to true after validation
        )

        // Optional DEBUG overrides (no-op in Release). Safe to omit if you don't have it.
        // FlagOverrides.apply(to: &flags)

        // FINAL CLAMP: never allow ML on when no compiled model is present
        if flags.useMLDetection && !hasCompiledML {
            flags.useMLDetection = false
        }

        precondition((0.0...1.0).contains(flags.modelConfidenceThreshold),
                     "FeatureFlags.modelConfidenceThreshold must be 0...1")
        return flags
    }
}
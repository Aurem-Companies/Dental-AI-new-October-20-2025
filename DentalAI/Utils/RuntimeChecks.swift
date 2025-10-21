import Foundation
import os

enum RuntimeChecks {
    private static let log = Logger(subsystem: "com.yourorg.DentalAI", category: "RuntimeChecks")

    static func validateFlags(_ flags: FeatureFlags) {
        let hasML = ModelLocator.anyCompiledMLExists()
        if flags.useMLDetection && !hasML {
            // Log a loud message but DO NOT crash
            #if DEBUG
            log.error("ML enabled by flags but no .mlmodelc found in bundle — ML will be OFF; using ONNX/CV.")
            #else
            log.fault("ML enabled but no .mlmodelc found — falling back to CV.")
            #endif
        }
    }
}
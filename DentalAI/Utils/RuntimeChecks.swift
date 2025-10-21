import Foundation
import os

enum RuntimeChecks {
    private static let log = Logger(subsystem: "com.yourorg.DentalAI", category: "RuntimeChecks")

    static func validateFlags(_ flags: FeatureFlags) {
        #if DEBUG
        if flags.useMLDetection && !ModelLocator.anyCompiledMLExists() {
            assertionFailure("FeatureFlags.useMLDetection = true but no .mlmodelc in bundle.")
        }
        #else
        if flags.useMLDetection && !ModelLocator.anyCompiledMLExists() {
            log.fault("ML enabled but model missing; auto-falling back to CV.")
        }
        #endif
    }
}
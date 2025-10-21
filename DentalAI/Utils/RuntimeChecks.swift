import Foundation
import os

enum RuntimeChecks {
    private static let log = Logger(subsystem: "com.yourorg.DentalAI", category: "RuntimeChecks")

    static func validateFlags(_ flags: FeatureFlags) {
        let mlPresent = ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc")
        #if DEBUG
        if flags.useMLDetection && !mlPresent {
            assertionFailure("FeatureFlags.useMLDetection = true but DentalModel.mlmodelc not in bundle.")
        }
        #else
        if flags.useMLDetection && !mlPresent {
            log.fault("ML enabled but model missing; auto-falling back to CV.")
        }
        #endif
    }
}
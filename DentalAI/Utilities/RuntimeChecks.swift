import Foundation

enum RuntimeChecks {
    static func validateFlags(_ flags: FeatureFlags) {
        let mlPresent = ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc")
        if flags.useMLDetection && !mlPresent {
            assertionFailure("FeatureFlags.useMLDetection = true but DentalModel.mlmodelc not in bundle.")
        }
    }
}

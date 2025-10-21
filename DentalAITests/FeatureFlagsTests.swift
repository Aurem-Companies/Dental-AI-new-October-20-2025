import XCTest
@testable import DentalAI

final class FeatureFlagsTests: XCTestCase {
    func testCurrentProducesSaneValues() {
        let f = FeatureFlags.current
        XCTAssertTrue(f.useCVDetection, "CV fallback should be on by default")
        XCTAssertTrue((0...1).contains(f.modelConfidenceThreshold))
        if f.useMLDetection {
            XCTAssertTrue(ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc"),
                          "ML should only be on if .mlmodelc exists")
        }
    }
}

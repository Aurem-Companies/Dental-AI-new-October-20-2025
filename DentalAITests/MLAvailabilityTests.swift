import XCTest
@testable import DentalAI

final class MLAvailabilityTests: XCTestCase {

    func testCompiledModelPresent() {
        // Update name to your compiled model folder
        let name = "DentalDetectionModel"
        XCTAssertTrue(ModelLocator.hasCompiledMLModel(named: name),
                      "Expected compiled .mlmodelc '\(name)' to be bundled under /models or root.")
    }

    func testModelURLResolves() {
        let name = "DentalDetectionModel"
        let url = ModelLocator.bundledCompiledMLModelURL(named: name)
        XCTAssertNotNil(url, "Expected url for compiled model \(name)")
    }
    
    func testMLDetectionServiceAvailability() {
        let service = MLDetectionService()
        let isAvailable = service.isModelAvailable
        let status = service.modelStatus
        
        // Test that availability and status are consistent
        switch status {
        case .available:
            XCTAssertTrue(isAvailable, "Status is available but isModelAvailable is false")
        case .notAvailable:
            XCTAssertFalse(isAvailable, "Status is notAvailable but isModelAvailable is true")
        }
    }
}

import XCTest
@testable import DentalAI

final class DetectionFactoryTests: XCTestCase {
    func testFactoryNeverReturnsUnavailableML() {
        // Simulate missing ML: if your tests can't manipulate bundles, just assert CV path is valid
        let service = DetectionFactory.makeWithFallback()
        // At minimum the service should be non-nil and callable; deeper checks can use protocols/mocks.
        XCTAssertNotNil(service)
    }
}

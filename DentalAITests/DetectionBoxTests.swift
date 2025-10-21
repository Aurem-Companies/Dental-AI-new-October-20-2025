import XCTest
@testable import DentalAI
import CoreGraphics

final class DetectionBoxTests: XCTestCase {
    func testPercentCalculation() {
        let box = DetectionBox(rect: .zero, label: "Tooth", confidence: 0.875)
        XCTAssertEqual(box.confidencePercent, 88)
    }

    func testClampWithinBounds() {
        let original = DetectionBox(rect: CGRect(x: -10, y: 10, width: 50, height: 50),
                                    label: "Cavity", confidence: 0.6)
        let clamped = original.clamped(to: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(clamped.rect.origin.x, 0)
        XCTAssertLessThanOrEqual(clamped.rect.maxX, 100)
    }
    
    func testEquatable() {
        let b1 = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Test", confidence: 0.5)
        let b2 = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Test", confidence: 0.5)
        let b3 = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Different", confidence: 0.5)
        
        XCTAssertEqual(b1, b2)
        XCTAssertNotEqual(b1, b3)
    }
    
    func testHashable() {
        let b1 = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Test", confidence: 0.5)
        let b2 = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Test", confidence: 0.5)
        
        XCTAssertEqual(b1.hashValue, b2.hashValue)
    }
    
    func testCodable() throws {
        let original = DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), label: "Test", confidence: 0.5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DetectionBox.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
}
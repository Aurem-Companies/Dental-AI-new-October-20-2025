import XCTest
@testable import DentalAI
import UIKit

final class ResultExporterTests: XCTestCase {

    func testRenderProducesImage() {
        // Create a 200x200 test image
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 200, height: 200), false, 2)
        UIColor.black.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 200, height: 200))
        let base = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        XCTAssertNotNil(base)

        let boxes = [
            DetectionBox(rect: CGRect(x: 20, y: 20, width: 80, height: 50),
                         label: "Cavity", confidence: 0.87),
            DetectionBox(rect: CGRect(x: 100, y: 120, width: 60, height: 60),
                         label: "Crack", confidence: 0.62)
        ]

        let out = ResultExporter.render(
            image: base!,
            detections: boxes,
            modelVersion: "1.0",
            date: Date(timeIntervalSince1970: 0)
        )
        XCTAssertEqual(out.size, base!.size)
        XCTAssertGreaterThan(out.pngData()?.count ?? 0, 0)
    }
    
    func testRenderWithEmptyDetections() {
        // Test with no detections
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 100, height: 100), false, 2)
        UIColor.blue.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 100, height: 100))
        let base = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let out = ResultExporter.render(
            image: base!,
            detections: [],
            modelVersion: "2.0",
            date: Date()
        )
        XCTAssertEqual(out.size, base!.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testRenderWithOutOfBoundsDetections() {
        // Test with detections that go outside image bounds
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 50, height: 50), false, 2)
        UIColor.green.setFill()
        UIRectFill(CGRect(x: 0, y: 0, width: 50, height: 50))
        let base = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let boxes = [
            DetectionBox(rect: CGRect(x: -10, y: -10, width: 100, height: 100), // Out of bounds
                         label: "Test", confidence: 0.5),
            DetectionBox(rect: CGRect(x: 10, y: 10, width: 20, height: 20), // In bounds
                         label: "Valid", confidence: 0.8)
        ]
        
        let out = ResultExporter.render(
            image: base!,
            detections: boxes,
            modelVersion: "1.5",
            date: Date()
        )
        XCTAssertEqual(out.size, base!.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testRenderPreservesImageOrientation() {
        // Test that image orientation is preserved
        let testImage = createTestImage(size: CGSize(width: 100, height: 200))
        let boxes = [
            DetectionBox(rect: CGRect(x: 10, y: 10, width: 30, height: 30),
                         label: "Test", confidence: 0.7)
        ]
        
        let out = ResultExporter.render(
            image: testImage,
            detections: boxes,
            modelVersion: "1.0",
            date: Date()
        )
        
        XCTAssertEqual(out.size, testImage.size)
        XCTAssertEqual(out.imageOrientation, testImage.imageOrientation)
    }
    
    func testRenderWithHighConfidence() {
        // Test with very high confidence values
        let testImage = createTestImage(size: CGSize(width: 150, height: 150))
        let boxes = [
            DetectionBox(rect: CGRect(x: 20, y: 20, width: 50, height: 50),
                         label: "HighConfidence", confidence: 0.99)
        ]
        
        let out = ResultExporter.render(
            image: testImage,
            detections: boxes,
            modelVersion: "1.0",
            date: Date()
        )
        
        XCTAssertEqual(out.size, testImage.size)
        XCTAssertNotNil(out.pngData())
    }
    
    // Helper method to create test images
    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        UIColor.red.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}

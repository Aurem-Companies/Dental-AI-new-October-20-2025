import XCTest
@testable import DentalAI
import UIKit

final class ResultExporterBasicTests: XCTestCase {

    private func solidImage(size: CGSize = .init(width: 200, height: 200)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

    func testRenderClampedProducesImage() {
        let base = solidImage()
        let boxes = [
            DetectionBox(rect: CGRect(x: 10, y: 10, width: 80, height: 50), label: "Cavity", confidence: 0.87),
            DetectionBox(rect: CGRect(x: 180, y: 180, width: 80, height: 80), label: "Edge", confidence: 0.25) // will clamp
        ]
        let out = ResultExporter.renderClamped(image: base, detections: boxes, modelVersion: "1.0", date: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(out.size, base.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testRenderWithCGImage() {
        let base = solidImage()
        guard let cgImage = base.cgImage else {
            XCTFail("Could not get CGImage from test image")
            return
        }
        
        let boxes = [
            DetectionBox(rect: CGRect(x: 20, y: 20, width: 60, height: 40), label: "Test", confidence: 0.75)
        ]
        
        let out = ResultExporter.render(
            cgImage: cgImage,
            scale: 2.0,
            orientation: .up,
            detections: boxes,
            modelVersion: "2.0",
            date: Date()
        )
        
        XCTAssertEqual(out.size, base.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testRenderWithEmptyDetections() {
        let base = solidImage()
        let out = ResultExporter.renderClamped(image: base, detections: [], modelVersion: "1.0", date: Date())
        
        XCTAssertEqual(out.size, base.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testExportPNG() throws {
        let base = solidImage()
        let url = try ResultExporter.exportPNG(image: base, filename: "test.png")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.lastPathComponent, "test.png")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}

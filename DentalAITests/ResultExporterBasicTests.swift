import XCTest
@testable import DentalAI
import UIKit

final class ResultExporterBasicTests: XCTestCase {
    private func makeSolidImage(size: CGSize = .init(width: 200, height: 200)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 2)
        UIColor.black.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

    func testRenderClampedProducesImage() {
        let img = makeSolidImage()
        let boxes = [
            DetectionBox(rect: CGRect(x: 10, y: 10, width: 80, height: 50),
                         label: "Cavity", confidence: 0.87)
        ]
        let output = ResultExporter.renderClamped(
            image: img,
            detections: boxes,
            modelVersion: "1.0",
            date: Date()
        )
        XCTAssertEqual(output.size, img.size)
        XCTAssertNotNil(output.pngData())
    }
    
    func testRenderWithCGImage() {
        let base = makeSolidImage()
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
        let base = makeSolidImage()
        let out = ResultExporter.renderClamped(image: base, detections: [], modelVersion: "1.0", date: Date())
        
        XCTAssertEqual(out.size, base.size)
        XCTAssertNotNil(out.pngData())
    }
    
    func testExportPNG() throws {
        let base = makeSolidImage()
        let url = try ResultExporter.exportPNG(image: base, filename: "test.png")
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.lastPathComponent, "test.png")
        
        // Clean up
        try? FileManager.default.removeItem(at: url)
    }
}
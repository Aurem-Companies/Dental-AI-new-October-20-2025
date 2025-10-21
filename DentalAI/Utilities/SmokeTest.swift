import Foundation
import CoreVideo
import CoreGraphics
import UIKit

enum SmokeTestResult {
    case success(count: Int, avgConfidence: Double, backend: String)
    case failure(String)
}

enum SmokeTest {
    static func run() -> SmokeTestResult {
        // 1) Load bundled image
        guard let url = Bundle.main.url(forResource: "sample_teeth", withExtension: "jpg") else {
            return .failure("sample_teeth.jpg not found in bundle. Add it under DentalAI/Resources/TestAssets and check target membership.")
        }
        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data),
              let cg = img.cgImage else {
            return .failure("Failed to load CGImage from sample_teeth.jpg")
        }

        // 2) Convert to CVPixelBuffer (simple BGRA buffer)
        guard let pb = cg.toPixelBuffer() else {
            return .failure("Failed to convert CGImage to CVPixelBuffer")
        }

        // 3) Use production factory
        let flags = FeatureFlags.current
        RuntimeChecks.validateFlags(flags)

        let service = DetectionFactory.makeWithFallback()
        let backend = BackendStatus.lastUsed // updated by factory

        // 4) Run detection
        let t0 = CFAbsoluteTimeGetCurrent()
        let results = service.detect(in: pb)
        let dt = (CFAbsoluteTimeGetCurrent() - t0) * 1000.0

        guard !results.isEmpty else {
            return .failure("No detections returned (backend=\(backend), \(Int(dt))ms)")
        }

        let avg = results.map(\.confidence).reduce(0, +) / Double(results.count)
        return .success(count: results.count, avgConfidence: avg, backend: backend)
    }
}

// MARK: - CGImage → CVPixelBuffer helper
fileprivate extension CGImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        var pxbuf: CVPixelBuffer?
        let width = self.width
        let height = self.height
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
                                         kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pxbuf)
        guard status == kCVReturnSuccess, let buffer = pxbuf else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer),
                                      width: width, height: height,
                                      bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        else { return nil }

        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
}

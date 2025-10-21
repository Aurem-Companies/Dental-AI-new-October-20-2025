import UIKit
import Accelerate

enum ImagePreprocessor {
    /// Resize to 640x640, convert BGRA → RGB, normalize to 0..1, and output Float32 NCHW in [1,3,640,640]
    static func makeNCHWInput(from image: UIImage, size: Int = 640) -> (data: Data, shape: [NSNumber])? {
        guard let cg = image.cgImage else { return nil }
        let width = size, height = size

        // 1) Create BGRA pixel buffer for the target size
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var bgra = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let ctx = CGContext(
            data: &bgra,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // 2) Draw (this resizes with CoreGraphics; letterbox/pad if you need aspect preservation later)
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 3) Split BGRA → separate R,G,B planes, normalize to 0..1, and arrange to NCHW
        let count = width * height
        var r = [Float](repeating: 0, count: count)
        var g = [Float](repeating: 0, count: count)
        var b = [Float](repeating: 0, count: count)

        // BGRA layout (little endian): [B, G, R, A]
        var idx = 0
        for i in 0..<count {
            let b8 = bgra[idx + 0]
            let g8 = bgra[idx + 1]
            let r8 = bgra[idx + 2]
            // ignore A
            r[i] = Float(r8) / 255.0
            g[i] = Float(g8) / 255.0
            b[i] = Float(b8) / 255.0
            idx += 4
        }

        // NCHW: [1, 3, H, W]
        var nchw = [Float](repeating: 0, count: 3 * count)
        // channel stride = H*W
        let plane = count
        // Row-major fill per channel
        nchw[0..<plane] = r[0..<plane]
        nchw[plane..<(2*plane)] = g[0..<plane]
        nchw[(2*plane)..<(3*plane)] = b[0..<plane]

        let data = Data(bytes: nchw, count: nchw.count * MemoryLayout<Float>.size)
        return (data, [1, 3, NSNumber(value: height), NSNumber(value: width)])
    }
}

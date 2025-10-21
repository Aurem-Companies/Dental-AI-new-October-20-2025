import Foundation
import UIKit
import CoreGraphics

struct ResultExporter {

    enum ExportError: Error {
        case encodingFailed
    }

    /// Renders detection boxes + footer onto a copy of the input image.
    /// Returns a new UIImage suitable for sharing/saving.
    static func render(
        image: UIImage,
        detections: [DetectionBox],
        modelVersion: String,
        date: Date
    ) -> UIImage {
        // Ensure we render at the image's natural size/scale.
        let size = image.size
        let format = UIGraphicsImageRendererFormat()
        // Use at least 2x for crisp text on simulators that report 1.0
        format.scale = max(image.scale, 2.0)
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { ctx in
            // Draw base image
            image.draw(in: CGRect(origin: .zero, size: size))

            // Draw each detection box + label
            for box in detections {
                // Clamp to bounds
                let bounds = CGRect(origin: .zero, size: size)
                let r = box.rect.integral.intersection(bounds)
                guard r.width > 0, r.height > 0 else { continue }

                // Box (dashed white)
                let path = UIBezierPath(rect: r)
                path.setLineDash([6, 3], count: 2, phase: 0)
                path.lineWidth = 2
                UIColor.white.setStroke()
                path.stroke()

                // Label text
                let pct = Int(round(Double(box.confidence) * 100.0))
                let text = "\(box.label) • \(pct)%"

                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.white
                ]

                // Size + background pill
                let textSize = (text as NSString).size(withAttributes: attrs)
                // Place above the box; clamp to top
                let labelRect = CGRect(
                    x: r.minX,
                    y: max(0, r.minY - textSize.height - 6),
                    width: textSize.width + 10,
                    height: textSize.height + 6
                )

                // Background pill
                let pill = UIBezierPath(roundedRect: labelRect, cornerRadius: 4)
                UIColor.black.withAlphaComponent(0.6).setFill()
                pill.fill()

                // Draw text inset
                (text as NSString).draw(
                    in: labelRect.insetBy(dx: 5, dy: 3),
                    withAttributes: attrs
                )
            }

            // Footer legend
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let footer = "DentalAI — non-diagnostic • v\(modelVersion) • \(df.string(from: date))"

            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.white
            ]

            let fSize = (footer as NSString).size(withAttributes: footerAttrs)
            let fRect = CGRect(
                x: 8,
                y: size.height - fSize.height - 10,
                width: fSize.width + 12,
                height: fSize.height + 8
            )

            let footerBG = UIBezierPath(roundedRect: fRect, cornerRadius: 4)
            UIColor.black.withAlphaComponent(0.5).setFill()
            footerBG.fill()

            (footer as NSString).draw(
                in: fRect.insetBy(dx: 6, dy: 4),
                withAttributes: footerAttrs
            )
        }

        return rendered
    }

    /// Optional: export to a temp PNG for sharing. Not used by ImageAnalysisView, but handy.
    static func exportPNG(image: UIImage, filename: String = "analysis.png") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        guard let data = image.pngData() else { throw ExportError.encodingFailed }
        try data.write(to: url, options: .atomic)
        return url
    }
}

extension ResultExporter {
    /// Convenience: accept CGImage directly.
    static func render(
        cgImage: CGImage,
        scale: CGFloat = 2.0,
        orientation: UIImage.Orientation = .up,
        detections: [DetectionBox],
        modelVersion: String,
        date: Date
    ) -> UIImage {
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        return render(image: image, detections: detections, modelVersion: modelVersion, date: date)
    }

    /// Convenience: draw after clamping to image bounds.
    static func renderClamped(
        image: UIImage,
        detections: [DetectionBox],
        modelVersion: String,
        date: Date
    ) -> UIImage {
        let bounds = CGRect(origin: .zero, size: image.size)
        let clamped = detections.map { $0.clamped(to: bounds) }
        return render(image: image, detections: clamped, modelVersion: modelVersion, date: date)
    }
}
import UIKit
import CoreGraphics

// MARK: - Detection Box
struct DetectionBox {
    let rect: CGRect
    let label: String
    let confidence: Float
}

// MARK: - Result Exporter
struct ResultExporter {
    
    static func render(image: UIImage, detections: [DetectionBox], modelVersion: String, date: Date) -> UIImage {
        // Use UIGraphicsImageRenderer with proper format for retina and transparency
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(UIScreen.main.scale, 2) // guard retina
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        
        let out = renderer.image { ctx in
            // Draw original image (preserves orientation at UI level)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Draw detection boxes (clamped to image bounds)
            for detection in detections {
                let r = detection.rect.integral
                    .intersection(CGRect(origin: .zero, size: image.size))
                guard r.width > 0, r.height > 0 else { continue }
                
                // Draw box with dashed border
                let path = UIBezierPath(rect: r)
                UIColor.white.withAlphaComponent(0.8).setStroke()
                path.setLineDash([6, 3], count: 2, phase: 0)
                path.lineWidth = 2
                path.stroke()
                
                // Draw label with background
                let label = "\(detection.label) • \(Int(round(Double(detection.confidence) * 100)))%"
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
                    .foregroundColor: UIColor.white,
                    .backgroundColor: UIColor.black.withAlphaComponent(0.6)
                ]
                let size = (label as NSString).size(withAttributes: attrs)
                let labelRect = CGRect(x: r.minX, y: max(r.minY - size.height - 4, 0),
                                     width: size.width + 8, height: size.height + 4)
                UIBezierPath(roundedRect: labelRect, cornerRadius: 4).fill(with: .normal, alpha: 0.6)
                (label as NSString).draw(in: labelRect.insetBy(dx: 4, dy: 2), withAttributes: attrs)
            }
            
            // Draw footer legend
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let footer = "DentalAI — non-diagnostic • v\(modelVersion) • \(df.string(from: date))"
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.white,
                .backgroundColor: UIColor.black.withAlphaComponent(0.5)
            ]
            let fSize = (footer as NSString).size(withAttributes: footerAttrs)
            let fRect = CGRect(x: 8,
                             y: image.size.height - fSize.height - 8,
                             width: fSize.width + 10,
                             height: fSize.height + 6)
            UIBezierPath(roundedRect: fRect, cornerRadius: 4).fill()
            (footer as NSString).draw(in: fRect.insetBy(dx: 5, dy: 3), withAttributes: footerAttrs)
        }
        return out
}

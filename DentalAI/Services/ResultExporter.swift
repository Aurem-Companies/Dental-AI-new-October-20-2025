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
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // Draw original image
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            // Draw detection boxes
            for detection in detections {
                drawDetectionBox(detection, in: context.cgContext)
            }
            
            // Draw footer legend
            drawFooterLegend(modelVersion: modelVersion, date: date, imageSize: image.size, in: context.cgContext)
        }
    }
    
    private static func drawDetectionBox(_ detection: DetectionBox, in context: CGContext) {
        let boxRect = detection.rect
        
        // Draw semi-transparent background
        context.setFillColor(UIColor.red.withAlphaComponent(0.3).cgColor)
        context.fill(boxRect)
        
        // Draw border
        context.setStrokeColor(UIColor.red.cgColor)
        context.setLineWidth(2.0)
        context.stroke(boxRect)
        
        // Draw label with background
        let confidencePercent = Int(detection.confidence * 100)
        let labelText = "\(detection.label) (\(confidencePercent)%)"
        
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        let textSize = labelText.size(withAttributes: attributes)
        let labelRect = CGRect(
            x: boxRect.minX,
            y: boxRect.minY - textSize.height - 4,
            width: textSize.width + 8,
            height: textSize.height + 4
        )
        
        // Draw label background
        context.setFillColor(UIColor.black.withAlphaComponent(0.7).cgColor)
        context.fill(labelRect)
        
        // Draw label text
        labelText.draw(in: labelRect.insetBy(dx: 4, dy: 2), withAttributes: attributes)
    }
    
    private static func drawFooterLegend(modelVersion: String, date: Date, imageSize: CGSize, in context: CGContext) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let dateString = formatter.string(from: date)
        
        let legendText = "DentalAI — non-diagnostic • \(modelVersion) • \(dateString)"
        
        let font = UIFont.systemFont(ofSize: 12, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        let textSize = legendText.size(withAttributes: attributes)
        let legendRect = CGRect(
            x: 8,
            y: imageSize.height - textSize.height - 8,
            width: textSize.width + 16,
            height: textSize.height + 8
        )
        
        // Draw legend background
        context.setFillColor(UIColor.black.withAlphaComponent(0.8).cgColor)
        context.fill(legendRect)
        
        // Draw legend text
        legendText.draw(in: legendRect.insetBy(dx: 8, dy: 4), withAttributes: attributes)
    }
}

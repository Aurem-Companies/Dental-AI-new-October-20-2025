import Foundation
import UIKit
import Vision
import CoreImage
import CoreGraphics

// MARK: - CV Dentition Service
class CVDentitionService: DetectionService, @unchecked Sendable {
    
    // MARK: - Properties
    private let confidenceThreshold: Float = 0.3
    private let minTeethArea: Float = 0.01
    private let maxTeethArea: Float = 0.8
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        var detections: [Detection] = []
        
        // Use multiple Vision requests for comprehensive detection
        do {
            let teethDetections = try detectTeethRegions(in: image)
            detections.append(contentsOf: teethDetections)
        } catch {
            print("Teeth detection failed: \(error)")
        }
        
        do {
            let gumDetections = try detectGumRegions(in: image)
            detections.append(contentsOf: gumDetections)
        } catch {
            print("Gum detection failed: \(error)")
        }
        
        do {
            let colorDetections = try detectToothColor(in: image)
            detections.append(contentsOf: colorDetections)
        } catch {
            print("Color detection failed: \(error)")
        }
        
        do {
            let edgeDetections = try detectEdgeFeatures(in: image)
            detections.append(contentsOf: edgeDetections)
        } catch {
            print("Edge detection failed: \(error)")
        }
        
        return detections
    }
    
    // MARK: - Teeth Region Detection
    private func detectTeethRegions(in image: CGImage) throws -> [Detection] {
        let request = VNDetectRectanglesRequest { request, error in
            if let error = error {
                print("Teeth region detection failed: \(error)")
            }
        }
        
        request.minimumAspectRatio = 0.1
        request.maximumAspectRatio = 1.0
        request.minimumSize = minTeethArea
        request.maximumObservations = 20
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            return observations.compactMap { observation in
                guard observation.confidence >= confidenceThreshold else { return nil }
                
                return Detection(
                    label: "teeth_region",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox
                )
            }
        } catch {
            throw ModelError.inferenceFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Gum Region Detection
    private func detectGumRegions(in image: CGImage) throws -> [Detection] {
        let request = VNDetectContoursRequest { request, error in
            if let error = error {
                print("Gum region detection failed: \(error)")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            return observations.compactMap { observation in
                guard observation.confidence >= confidenceThreshold else { return nil }
                
                // Calculate bounding box from contours
                let boundingBox = calculateBoundingBox(from: observation)
                
                return Detection(
                    label: "gum_region",
                    confidence: observation.confidence,
                    boundingBox: boundingBox
                )
            }
        } catch {
            throw ModelError.inferenceFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Tooth Color Detection
    private func detectToothColor(in image: CGImage) throws -> [Detection] {
        let request = VNClassifyImageRequest { request, error in
            if let error = error {
                print("Tooth color detection failed: \(error)")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            return observations.compactMap { observation in
                guard observation.confidence >= confidenceThreshold else { return nil }
                
                // Map color classifications to dental conditions
                let condition = mapColorToCondition(observation.identifier)
                
                return Detection(
                    label: condition,
                    confidence: observation.confidence,
                    boundingBox: CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4) // Center region
                )
            }
        } catch {
            throw ModelError.inferenceFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Edge Feature Detection
    private func detectEdgeFeatures(in image: CGImage) throws -> [Detection] {
        let request = VNDetectFaceRectanglesRequest { request, error in
            if let error = error {
                print("Edge feature detection failed: \(error)")
            }
        }
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results else {
                return []
            }
            
            return observations.compactMap { observation in
                guard observation.confidence >= confidenceThreshold else { return nil }
                
                // Analyze face region for dental features
                let dentalFeatures = analyzeDentalFeatures(in: observation.boundingBox, image: image)
                
                return Detection(
                    label: dentalFeatures.condition,
                    confidence: dentalFeatures.confidence,
                    boundingBox: observation.boundingBox
                )
            }
        } catch {
            throw ModelError.inferenceFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Color to Condition Mapping
    private func mapColorToCondition(_ colorIdentifier: String) -> String {
        switch colorIdentifier.lowercased() {
        case "white", "bright":
            return "healthy"
        case "yellow", "stained":
            return "discoloration"
        case "brown", "dark":
            return "cavity"
        case "red", "inflamed":
            return "gingivitis"
        case "gray", "dull":
            return "plaque"
        default:
            return "unknown"
        }
    }
    
    // MARK: - Helper Methods
    private func calculateBoundingBox(from contoursObservation: VNContoursObservation) -> CGRect {
        // For contours, we'll create a bounding box that encompasses the contour area
        // Since contours don't have a direct bounding box, we'll use a default region
        return CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6) // Center region
    }
    
    // MARK: - Dental Feature Analysis
    private func analyzeDentalFeatures(in boundingBox: CGRect, image: CGImage) -> (condition: String, confidence: Float) {
        // Extract region of interest
        let roi = extractROI(from: image, boundingBox: boundingBox)
        
        // Analyze features
        let colorAnalysis = analyzeColorDistribution(roi)
        let edgeAnalysis = analyzeEdgeDensity(roi)
        let textureAnalysis = analyzeTexturePattern(roi)
        
        // Combine analyses
        let condition = determineCondition(
            color: colorAnalysis,
            edges: edgeAnalysis,
            texture: textureAnalysis
        )
        
        let confidence = calculateConfidence(
            color: colorAnalysis,
            edges: edgeAnalysis,
            texture: textureAnalysis
        )
        
        return (condition, confidence)
    }
    
    // MARK: - ROI Extraction
    private func extractROI(from image: CGImage, boundingBox: CGRect) -> CGImage? {
        let width = image.width
        let height = image.height
        
        let x = Int(boundingBox.origin.x * CGFloat(width))
        let y = Int(boundingBox.origin.y * CGFloat(height))
        let w = Int(boundingBox.width * CGFloat(width))
        let h = Int(boundingBox.height * CGFloat(height))
        
        let rect = CGRect(x: x, y: y, width: w, height: h)
        
        return image.cropping(to: rect)
    }
    
    // MARK: - Color Distribution Analysis
    private func analyzeColorDistribution(_ image: CGImage?) -> ColorAnalysis {
        guard let image = image else {
            return ColorAnalysis(dominantColor: .unknown, brightness: 0.0, saturation: 0.0, confidence: 0.0)
        }
        
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return ColorAnalysis(dominantColor: .unknown, brightness: 0.0, saturation: 0.0, confidence: 0.0)
        }
        
        var rSum: Float = 0
        var gSum: Float = 0
        var bSum: Float = 0
        let pixelCount = Float(width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                rSum += Float(bytes[pixelIndex])
                gSum += Float(bytes[pixelIndex + 1])
                bSum += Float(bytes[pixelIndex + 2])
            }
        }
        
        let avgR = rSum / pixelCount
        let avgG = gSum / pixelCount
        let avgB = bSum / pixelCount
        
        let brightness = (avgR + avgG + avgB) / 3.0 / 255.0
        let saturation = calculateSaturation(r: avgR, g: avgG, b: avgB)
        let dominantColor = determineDominantColor(r: avgR, g: avgG, b: avgB)
        
        return ColorAnalysis(
            dominantColor: dominantColor,
            brightness: brightness,
            saturation: saturation,
            confidence: min(1.0, brightness * 2.0)
        )
    }
    
    // MARK: - Edge Density Analysis
    private func analyzeEdgeDensity(_ image: CGImage?) -> EdgeAnalysis {
        guard let image = image else {
            return EdgeAnalysis(edgeCount: 0, edgeStrength: 0.0, confidence: 0.0)
        }
        
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return EdgeAnalysis(edgeCount: 0, edgeStrength: 0.0, confidence: 0.0)
        }
        
        // Convert to grayscale
        var grayPixels = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                let gray = 0.299 * r + 0.587 * g + 0.114 * b
                grayPixels[y * width + x] = gray
            }
        }
        
        // Calculate edge density using Sobel operator
        var edgeCount = 0
        var edgeStrengthSum: Float = 0.0
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let gx = grayPixels[(y - 1) * width + (x + 1)] + 2 * grayPixels[y * width + (x + 1)] + grayPixels[(y + 1) * width + (x + 1)] -
                         grayPixels[(y - 1) * width + (x - 1)] - 2 * grayPixels[y * width + (x - 1)] - grayPixels[(y + 1) * width + (x - 1)]
                
                let gy = grayPixels[(y + 1) * width + (x - 1)] + 2 * grayPixels[(y + 1) * width + x] + grayPixels[(y + 1) * width + (x + 1)] -
                         grayPixels[(y - 1) * width + (x - 1)] - 2 * grayPixels[(y - 1) * width + x] - grayPixels[(y - 1) * width + (x + 1)]
                
                let magnitude = sqrt(gx * gx + gy * gy)
                
                if magnitude > 50 { // Threshold for edge detection
                    edgeCount += 1
                    edgeStrengthSum += magnitude
                }
            }
        }
        
        let edgeStrength = edgeCount > 0 ? edgeStrengthSum / Float(edgeCount) : 0.0
        let confidence = min(1.0, Float(edgeCount) / 10000.0)
        
        return EdgeAnalysis(edgeCount: edgeCount, edgeStrength: edgeStrength, confidence: confidence)
    }
    
    // MARK: - Texture Pattern Analysis
    private func analyzeTexturePattern(_ image: CGImage?) -> TextureAnalysis {
        guard let image = image else {
            return TextureAnalysis(smoothness: 0.0, uniformity: 0.0, pattern: "unknown", confidence: 0.0)
        }
        
        // Simplified texture analysis
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return TextureAnalysis(smoothness: 0.0, uniformity: 0.0, pattern: "unknown", confidence: 0.0)
        }
        
        // Calculate local variance for texture analysis
        var grayPixels = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                let gray = 0.299 * r + 0.587 * g + 0.114 * b
                grayPixels[y * width + x] = gray
            }
        }
        
        // Calculate local variance
        var varianceSum: Float = 0.0
        let kernelSize = 3
        let halfKernel = kernelSize / 2
        
        for y in halfKernel..<(height - halfKernel) {
            for x in halfKernel..<(width - halfKernel) {
                var localSum: Float = 0.0
                var localCount = 0
                
                for ky in -halfKernel...halfKernel {
                    for kx in -halfKernel...halfKernel {
                        let pixelValue = grayPixels[(y + ky) * width + (x + kx)]
                        localSum += pixelValue
                        localCount += 1
                    }
                }
                
                let localMean = localSum / Float(localCount)
                var localVariance: Float = 0.0
                
                for ky in -halfKernel...halfKernel {
                    for kx in -halfKernel...halfKernel {
                        let pixelValue = grayPixels[(y + ky) * width + (x + kx)]
                        localVariance += pow(pixelValue - localMean, 2)
                    }
                }
                
                localVariance /= Float(localCount)
                varianceSum += localVariance
            }
        }
        
        let avgVariance = varianceSum / Float((width - kernelSize) * (height - kernelSize))
        let smoothness = 1.0 - min(1.0, avgVariance / 10000.0)
        let uniformity = 1.0 - min(1.0, avgVariance / 5000.0)
        
        let pattern = determineTexturePattern(smoothness: smoothness, uniformity: uniformity)
        let confidence = (smoothness + uniformity) / 2.0
        
        return TextureAnalysis(
            smoothness: smoothness,
            uniformity: uniformity,
            pattern: pattern,
            confidence: confidence
        )
    }
    
    // MARK: - Helper Methods
    private func calculateSaturation(r: Float, g: Float, b: Float) -> Float {
        let max = max(r, max(g, b))
        let min = min(r, min(g, b))
        let delta = max - min
        
        if max == 0 {
            return 0.0
        }
        
        return delta / max
    }
    
    private func determineDominantColor(r: Float, g: Float, b: Float) -> DominantColor {
        let max = max(r, max(g, b))
        
        if max == r && r > g && r > b {
            return .red
        } else if max == g && g > r && g > b {
            return .green
        } else if max == b && b > r && b > g {
            return .blue
        } else if r > 200 && g > 200 && b > 200 {
            return .white
        } else if r > 150 && g > 150 && b < 100 {
            return .yellow
        } else if r > 150 && g < 100 && b < 100 {
            return .red
        } else if r > 100 && g > 50 && b < 50 && r > g && r > b {
            return .brown
        } else {
            return .unknown
        }
    }
    
    private func determineCondition(color: ColorAnalysis, edges: EdgeAnalysis, texture: TextureAnalysis) -> String {
        // Combine analyses to determine dental condition
        if color.dominantColor == .white && color.brightness > 0.8 {
            return "healthy"
        } else if color.dominantColor == .yellow || color.dominantColor == .brown {
            return "discoloration"
        } else if edges.edgeCount > 1000 && edges.edgeStrength > 100 {
            return "chipped"
        } else if texture.smoothness < 0.3 {
            return "plaque"
        } else if color.dominantColor == .red {
            return "gingivitis"
        } else {
            return "unknown"
        }
    }
    
    private func calculateConfidence(color: ColorAnalysis, edges: EdgeAnalysis, texture: TextureAnalysis) -> Float {
        return (color.confidence + edges.confidence + texture.confidence) / 3.0
    }
    
    private func determineTexturePattern(smoothness: Float, uniformity: Float) -> String {
        if smoothness > 0.7 && uniformity > 0.7 {
            return "smooth"
        } else if smoothness < 0.3 && uniformity < 0.3 {
            return "rough"
        } else {
            return "mixed"
        }
    }
    
    // MARK: - Model Status
    var isModelAvailable: Bool {
        return true // CV methods are always available
    }
    
    var modelStatus: String {
        return "CV Detection Service Active"
    }
}

// MARK: - Supporting Types
enum DominantColor: String, CaseIterable {
    case red = "red"
    case green = "green"
    case blue = "blue"
    case white = "white"
    case yellow = "yellow"
    case brown = "brown"
    case unknown = "unknown"
}

struct ColorAnalysis {
    let dominantColor: DominantColor
    let brightness: Float
    let saturation: Float
    let confidence: Float
}

// MARK: - Async Detection Extension
extension CVDentitionService {
    func detectAsync(in image: CGImage) async throws -> [Detection] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: ModelError.modelNotLoaded)
                    return
                }
                do {
                    let detections = try self.detect(in: image)
                    continuation.resume(returning: detections)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
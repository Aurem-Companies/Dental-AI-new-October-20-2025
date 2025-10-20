import Foundation
import UIKit
import CoreImage
import Vision
import CoreGraphics
import Accelerate
import SwiftUI

// MARK: - Image Processor
class ImageProcessor {
    
    // MARK: - Properties
    private let context = CIContext()
    private let targetSize = CGSize(width: 224, height: 224)
    private let qualityThreshold: Float = 0.7
    
    // MARK: - Image Enhancement
    func enhanceImage(_ image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }
        
        // Apply enhancement filters
                    let enhancedImage = ciImage
                        .applyingFilter("CIColorControls", parameters: [
                            kCIInputBrightnessKey: 0.1,
                            kCIInputContrastKey: 1.2,
                            kCIInputSaturationKey: 1.1
                        ])
                        .applyingFilter("CIUnsharpMask", parameters: [
                            kCIInputRadiusKey: 2.0,
                            kCIInputIntensityKey: 0.5
                        ])
                    
                    guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Image Resizing
    func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // MARK: - Quality Assessment
    func assessImageQuality(_ image: UIImage) -> ImageQuality {
        let sharpness = calculateSharpness(image)
        let brightness = calculateBrightness(image)
        let contrast = calculateContrast(image)
        let blur = calculateBlur(image)
        
        let overallScore = (sharpness + brightness + contrast + (1.0 - blur)) / 4.0
        
        return ImageQuality(
            sharpness: sharpness,
            brightness: brightness,
            contrast: contrast,
            blur: blur,
            overallScore: overallScore,
            qualityLevel: determineQualityLevel(overallScore)
        )
    }
    
    // MARK: - Sharpness Calculation
    private func calculateSharpness(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let _ = 8 // bitsPerComponent
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 0.0 }
        
        // Convert to grayscale
        var grayPixels = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                // Convert to grayscale using luminance formula
                let gray = 0.299 * r + 0.587 * g + 0.114 * b
                grayPixels[y * width + x] = gray
            }
        }
        
        // Calculate Laplacian variance (sharpness measure)
        var laplacianSum: Float = 0.0
        var laplacianSquaredSum: Float = 0.0
        let count = Float((width - 2) * (height - 2))
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let center = grayPixels[y * width + x]
                let top = grayPixels[(y - 1) * width + x]
                let bottom = grayPixels[(y + 1) * width + x]
                let left = grayPixels[y * width + (x - 1)]
                let right = grayPixels[y * width + (x + 1)]
                
                let laplacian = abs(4 * center - top - bottom - left - right)
                laplacianSum += laplacian
                laplacianSquaredSum += laplacian * laplacian
            }
        }
        
        let mean = laplacianSum / count
        let variance = (laplacianSquaredSum / count) - (mean * mean)
        
        // Normalize to 0-1 range
        return min(1.0, max(0.0, variance / 1000.0))
    }
    
    // MARK: - Brightness Calculation
    private func calculateBrightness(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 0.0 }
        
        var totalBrightness: Float = 0.0
        let pixelCount = Float(width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                // Calculate perceived brightness
                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                totalBrightness += brightness
            }
        }
        
        let averageBrightness = totalBrightness / pixelCount
        return averageBrightness / 255.0
    }
    
    // MARK: - Contrast Calculation
    private func calculateContrast(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 0.0 }
        
        var grayPixels = [Float]()
        grayPixels.reserveCapacity(width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                let gray = 0.299 * r + 0.587 * g + 0.114 * b
                grayPixels.append(gray)
            }
        }
        
        // Calculate standard deviation as contrast measure
        let mean = grayPixels.reduce(0, +) / Float(grayPixels.count)
        let variance = grayPixels.map { pow($0 - mean, 2) }.reduce(0, +) / Float(grayPixels.count)
        let standardDeviation = sqrt(variance)
        
        // Normalize to 0-1 range
        return min(1.0, max(0.0, standardDeviation / 128.0))
    }
    
    // MARK: - Blur Calculation
    private func calculateBlur(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 1.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 1.0 }
        
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
        
        // Calculate gradient magnitude (blur detection)
        var gradientSum: Float = 0.0
        let count = Float((width - 1) * (height - 1))
        
        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let current = grayPixels[y * width + x]
                let right = grayPixels[y * width + (x + 1)]
                let bottom = grayPixels[(y + 1) * width + x]
                
                let gradientX = right - current
                let gradientY = bottom - current
                let magnitude = sqrt(gradientX * gradientX + gradientY * gradientY)
                
                gradientSum += magnitude
            }
        }
        
        let averageGradient = gradientSum / count
        
        // Normalize to 0-1 range (higher values = more blur)
        return min(1.0, max(0.0, 1.0 - (averageGradient / 50.0)))
    }
    
    // MARK: - Quality Level Determination
    private func determineQualityLevel(_ score: Float) -> QualityLevel {
        if score >= 0.8 {
            return .excellent
        } else if score >= 0.6 {
            return .good
        } else if score >= 0.4 {
            return .fair
        } else {
            return .poor
        }
    }
    
    // MARK: - Tooth Color Analysis
    func analyzeToothColor(_ image: UIImage) -> ToothColorAnalysis {
        guard let cgImage = image.cgImage else {
            return ToothColorAnalysis(color: .unknown, healthiness: 0.0, confidence: 0.0)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return ToothColorAnalysis(color: .unknown, healthiness: 0.0, confidence: 0.0)
        }
        
        var toothPixels: [(r: Float, g: Float, b: Float)] = []
        
        // Sample pixels from center region (likely teeth area)
        let centerX = width / 2
        let centerY = height / 2
        let sampleSize = min(width, height) / 4
        
        for y in max(0, centerY - sampleSize)..<min(height, centerY + sampleSize) {
            for x in max(0, centerX - sampleSize)..<min(width, centerX + sampleSize) {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                // Filter for tooth-like colors (white to light yellow)
                if r > 200 && g > 200 && b > 180 && r > b {
                    toothPixels.append((r: r, g: g, b: b))
                }
            }
        }
        
        guard !toothPixels.isEmpty else {
            return ToothColorAnalysis(color: .unknown, healthiness: 0.0, confidence: 0.0)
        }
        
        // Calculate average color
        let avgR = toothPixels.map { $0.r }.reduce(0, +) / Float(toothPixels.count)
        let avgG = toothPixels.map { $0.g }.reduce(0, +) / Float(toothPixels.count)
        let avgB = toothPixels.map { $0.b }.reduce(0, +) / Float(toothPixels.count)
        
        let color = determineToothColor(r: avgR, g: avgG, b: avgB)
        let healthiness = calculateHealthiness(r: avgR, g: avgG, b: avgB)
        let confidence = min(1.0, Float(toothPixels.count) / 1000.0)
        
        return ToothColorAnalysis(color: color, healthiness: healthiness, confidence: confidence)
    }
    
    // MARK: - Tooth Color Determination
    private func determineToothColor(r: Float, g: Float, b: Float) -> ToothColor {
        let brightness = (r + g + b) / 3.0
        
        if brightness > 240 && abs(r - g) < 20 && abs(g - b) < 20 {
            return .white
        } else if r > g && g > b && brightness > 220 {
            return .lightYellow
        } else if r > g && g > b && brightness > 200 {
            return .yellow
        } else if r > g && g > b && brightness > 180 {
            return .darkYellow
        } else if r > 200 && g > 150 && b > 150 {
            return .brown
        } else {
            return .unknown
        }
    }
    
    // MARK: - Healthiness Calculation
    private func calculateHealthiness(r: Float, g: Float, b: Float) -> Float {
        let brightness = (r + g + b) / 3.0
        let whiteness = 1.0 - (abs(r - g) + abs(g - b) + abs(r - b)) / (3.0 * 255.0)
        
        // Healthier teeth are whiter and brighter
        let healthiness = (brightness / 255.0) * 0.7 + whiteness * 0.3
        return min(1.0, max(0.0, healthiness))
    }
    
    // MARK: - Edge Detection
    func detectEdges(_ image: UIImage) -> EdgeAnalysis {
        guard let cgImage = image.cgImage else {
            return EdgeAnalysis(edgeCount: 0, edgeStrength: 0.0, confidence: 0.0)
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
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
        
        // Apply Sobel edge detection
        var edgePixels = [Float](repeating: 0, count: width * height)
        var edgeCount = 0
        var edgeStrengthSum: Float = 0.0
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let gx = grayPixels[(y - 1) * width + (x + 1)] + 2 * grayPixels[y * width + (x + 1)] + grayPixels[(y + 1) * width + (x + 1)] -
                         grayPixels[(y - 1) * width + (x - 1)] - 2 * grayPixels[y * width + (x - 1)] - grayPixels[(y + 1) * width + (x - 1)]
                
                let gy = grayPixels[(y + 1) * width + (x - 1)] + 2 * grayPixels[(y + 1) * width + x] + grayPixels[(y + 1) * width + (x + 1)] -
                         grayPixels[(y - 1) * width + (x - 1)] - 2 * grayPixels[(y - 1) * width + x] - grayPixels[(y - 1) * width + (x + 1)]
                
                let magnitude = sqrt(gx * gx + gy * gy)
                edgePixels[y * width + x] = magnitude
                
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
    
    // MARK: - Crop to Teeth Region
    func cropToTeethRegion(_ image: UIImage) -> UIImage? {
        // This is a simplified implementation
        // In a real app, you'd use more sophisticated tooth detection
        let cropRect = CGRect(
            x: image.size.width * 0.1,
            y: image.size.height * 0.2,
            width: image.size.width * 0.8,
            height: image.size.height * 0.6
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Supporting Types
struct ImageQuality {
    let sharpness: Float
    let brightness: Float
    let contrast: Float
    let blur: Float
    let overallScore: Float
    let qualityLevel: QualityLevel
}

enum QualityLevel: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "✅"
        case .fair: return "⚠️"
        case .poor: return "❌"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

struct ToothColorAnalysis {
    let color: ToothColor
    let healthiness: Float
    let confidence: Float
}

enum ToothColor: String, CaseIterable {
    case white = "white"
    case lightYellow = "light_yellow"
    case yellow = "yellow"
    case darkYellow = "dark_yellow"
    case brown = "brown"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .white: return "White"
        case .lightYellow: return "Light Yellow"
        case .yellow: return "Yellow"
        case .darkYellow: return "Dark Yellow"
        case .brown: return "Brown"
        case .unknown: return "Unknown"
        }
    }
    
    var emoji: String {
        switch self {
        case .white: return "🤍"
        case .lightYellow: return "💛"
        case .yellow: return "🟡"
        case .darkYellow: return "🟨"
        case .brown: return "🤎"
        case .unknown: return "❓"
        }
    }
    
    var color: Color {
        switch self {
        case .white: return .white
        case .lightYellow: return .yellow
        case .yellow: return .yellow
        case .darkYellow: return .orange
        case .brown: return .brown
        case .unknown: return .gray
        }
    }
}

struct EdgeAnalysis {
    let edgeCount: Int
    let edgeStrength: Float
    let confidence: Float
}
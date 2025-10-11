import UIKit
import Vision
import CoreImage

// MARK: - Image Processing Protocol
protocol ImageProcessing {
    func enhanceImage(_ image: UIImage) async throws -> UIImage
    func assessImageQuality(_ image: UIImage) -> ImageQuality
    func analyzeToothColor(_ image: UIImage) async throws -> ToothColorAnalysis
    func detectEdges(_ image: UIImage) async throws -> UIImage?
    func cropToTeethRegion(_ image: UIImage) async throws -> UIImage?
}

class ImageProcessor: ObservableObject, ImageProcessing {
    
    // MARK: - Image Enhancement
    func enhanceImage(_ image: UIImage) async throws -> UIImage {
        guard let ciImage = CIImage(image: image) else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            // Use background queue for image processing to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Create context with optimized settings for performance
                    let context = CIContext(options: [
                        .workingColorSpace: CGColorSpace(name: CGColorSpace.sRGB),
                        .outputColorSpace: CGColorSpace(name: CGColorSpace.sRGB),
                        .cacheIntermediates: true,
                        .useSoftwareRenderer: false
                    ])
                    
                    // Apply filters for better dental analysis with optimized parameters
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
                    
                    // Use Metal for hardware acceleration if available
                    guard let cgImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
                        continuation.resume(throwing: AnalysisError.mlFailure("Failed to create enhanced image"))
                        return
                    }
                    
                    let result = UIImage(cgImage: cgImage)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: AnalysisError.mlFailure("Image enhancement failed: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    // MARK: - Image Quality Assessment
    func assessImageQuality(_ image: UIImage) -> ImageQuality {
        guard let cgImage = image.cgImage else {
            return ImageQuality(poor: true, issues: ["Invalid image format"])
        }
        
        var issues: [String] = []
        var poor = false
        
        // Check image size
        let width = cgImage.width
        let height = cgImage.height
        
        if width < 500 || height < 500 {
            issues.append("Image resolution too low")
            poor = true
        }
        
        // Check brightness
        let brightness = calculateBrightness(image)
        if brightness < 0.3 {
            issues.append("Image too dark")
            poor = true
        } else if brightness > 0.8 {
            issues.append("Image too bright")
            poor = true
        }
        
        // Check contrast
        let contrast = calculateContrast(image)
        if contrast < 0.2 {
            issues.append("Low contrast")
            poor = true
        }
        
        // Check blur
        let blur = calculateBlur(image)
        if blur > 0.5 {
            issues.append("Image appears blurry")
            poor = true
        }
        
        return ImageQuality(poor: poor, issues: issues)
    }
    
    // MARK: - Color Analysis
    func analyzeToothColor(_ image: UIImage) async throws -> ToothColorAnalysis {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0
        var pixelCount = 0
        
        // Sample pixels (every 10th pixel for performance)
        for y in stride(from: 0, to: height, by: 10) {
            for x in stride(from: 0, to: width, by: 10) {
                let pixelIndex = (y * width + x) * bytesPerPixel
                if pixelIndex + 2 < pixelData.count {
                    let r = Double(pixelData[pixelIndex])
                    let g = Double(pixelData[pixelIndex + 1])
                    let b = Double(pixelData[pixelIndex + 2])
                    
                    totalR += r
                    totalG += g
                    totalB += b
                    pixelCount += 1
                }
            }
        }
        
        guard pixelCount > 0 else {
            return ToothColorAnalysis(dominantColor: .unknown, healthiness: 0.0)
        }
        
        let avgR = totalR / Double(pixelCount)
        let avgG = totalG / Double(pixelCount)
        let avgB = totalB / Double(pixelCount)
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let dominantColor = self.determineToothColor(red: avgR, green: avgG, blue: avgB)
                    let healthiness = self.calculateHealthiness(red: avgR, green: avgG, blue: avgB)
                    
                    let result = ToothColorAnalysis(dominantColor: dominantColor, healthiness: healthiness)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: AnalysisError.mlFailure("Color analysis failed: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    // MARK: - Edge Detection
    func detectEdges(_ image: UIImage) async throws -> UIImage? {
        guard let ciImage = CIImage(image: image) else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let context = CIContext()
                    
                    let edgeImage = ciImage
                        .applyingFilter("CIEdges", parameters: [
                            kCIInputIntensityKey: 1.0
                        ])
                    
                    guard let cgImage = context.createCGImage(edgeImage, from: edgeImage.extent) else {
                        continuation.resume(throwing: AnalysisError.mlFailure("Failed to create edge image"))
                        return
                    }
                    
                    let result = UIImage(cgImage: cgImage)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: AnalysisError.mlFailure("Edge detection failed: \(error.localizedDescription)"))
                }
            }
        }
    }
    
    // MARK: - Crop to Teeth Region
    func cropToTeethRegion(_ image: UIImage) async throws -> UIImage? {
        // This is a simplified implementation
        // In a real app, you'd use more sophisticated tooth detection
        let cropRect = CGRect(
            x: image.size.width * 0.1,
            y: image.size.height * 0.3,
            width: image.size.width * 0.8,
            height: image.size.height * 0.4
        )
        
        guard let cgImage = image.cgImage?.cropping(to: cropRect) else {
            throw AnalysisError.mlFailure("Failed to crop image to teeth region")
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - Private Helper Methods
    // Exposed internally for use by other services (e.g., DentalAnalysisEngine)
    internal func calculateBrightness(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var totalBrightness: Double = 0
        var pixelCount = 0
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            
            // Calculate brightness using luminance formula
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            totalBrightness += brightness
            pixelCount += 1
        }
        
        return pixelCount > 0 ? totalBrightness / Double(pixelCount) : 0.0
    }
    
    internal func calculateContrast(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var brightnessValues: [Double] = []
        
        for i in stride(from: 0, to: pixelData.count, by: bytesPerPixel) {
            let r = Double(pixelData[i])
            let g = Double(pixelData[i + 1])
            let b = Double(pixelData[i + 2])
            
            let brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
            brightnessValues.append(brightness)
        }
        
        guard !brightnessValues.isEmpty else { return 0.0 }
        
        let mean = brightnessValues.reduce(0, +) / Double(brightnessValues.count)
        let variance = brightnessValues.map { pow($0 - mean, 2) }.reduce(0, +) / Double(brightnessValues.count)
        
        return sqrt(variance)
    }
    
    internal func calculateBlur(_ image: UIImage) -> Double {
        // Simplified blur detection using edge detection
        guard let edgeImage = detectEdges(image) else { return 0.0 }
        
        let edgeBrightness = calculateBrightness(edgeImage)
        let originalBrightness = calculateBrightness(image)
        
        // If edges are much dimmer than the original, the image is likely blurry
        return max(0, 1.0 - (edgeBrightness / originalBrightness))
    }
    
    private func determineToothColor(red: Double, green: Double, blue: Double) -> ToothColor {
        // Simple color classification based on RGB values
        if red > 200 && green > 200 && blue > 200 {
            return .white
        } else if red > 180 && green > 180 && blue > 150 {
            return .offWhite
        } else if red > 160 && green > 160 && blue > 120 {
            return .lightYellow
        } else if red > 140 && green > 140 && blue > 100 {
            return .yellow
        } else if red > 120 && green > 120 && blue > 80 {
            return .darkYellow
        } else if red < 100 && green < 100 && blue < 100 {
            return .black
        } else {
            return .brown
        }
    }
    
    private func calculateHealthiness(red: Double, green: Double, blue: Double) -> Double {
        // Healthiness score based on color (higher is healthier)
        let brightness = (red + green + blue) / 3.0
        let colorBalance = 1.0 - abs(red - green) / 255.0 - abs(green - blue) / 255.0
        
        return min(1.0, (brightness / 255.0 + colorBalance) / 2.0)
    }
}

// MARK: - Supporting Types
struct ImageQuality {
    let poor: Bool
    let issues: [String]
    
    var score: Int {
        return poor ? max(0, 100 - issues.count * 20) : 100
    }
}

struct ToothColorAnalysis {
    let dominantColor: ToothColor
    let healthiness: Double // 0.0 to 1.0
}

enum ToothColor: String, CaseIterable {
    case white = "White"
    case offWhite = "Off-White"
    case lightYellow = "Light Yellow"
    case yellow = "Yellow"
    case darkYellow = "Dark Yellow"
    case brown = "Brown"
    case black = "Black"
    case unknown = "Unknown"
    
    var healthiness: Double {
        switch self {
        case .white: return 1.0
        case .offWhite: return 0.9
        case .lightYellow: return 0.7
        case .yellow: return 0.5
        case .darkYellow: return 0.3
        case .brown: return 0.2
        case .black: return 0.1
        case .unknown: return 0.0
        }
    }
}

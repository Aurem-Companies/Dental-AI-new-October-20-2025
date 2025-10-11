import Foundation
import CoreGraphics
import CoreImage
import Vision

// MARK: - YOLO Preprocessor
class YOLOPreprocessor {
    
    // MARK: - Properties
    static let shared = YOLOPreprocessor()
    private let targetSize: CGFloat = 416.0
    
    private init() {}
    
    // MARK: - Image Preprocessing
    func preprocessImage(_ image: CGImage, targetSize: CGFloat = 416.0) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let context = CIContext()
        
        // Calculate scaling to maintain aspect ratio
        let originalSize = CGSize(width: image.width, height: image.height)
        let scale = min(targetSize / originalSize.width, targetSize / originalSize.height)
        
        // Calculate new size maintaining aspect ratio
        let newSize = CGSize(
            width: originalSize.width * scale,
            height: originalSize.height * scale
        )
        
        // Create scale transform
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
        let scaledImage = ciImage.transformed(by: scaleTransform)
        
        // Create padded image (square)
        let paddingX = (targetSize - newSize.width) / 2
        let paddingY = (targetSize - newSize.height) / 2
        
        let paddedImage = scaledImage.transformed(by: CGAffineTransform(
            translationX: paddingX,
            y: paddingY
        ))
        
        // Convert back to CGImage
        guard let outputImage = context.createCGImage(paddedImage, from: CGRect(x: 0, y: 0, width: targetSize, height: targetSize)) else {
            return nil
        }
        
        return outputImage
    }
    
    // MARK: - Color Space Conversion
    func convertToRGB(_ image: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let context = CIContext()
        
        // Ensure RGB color space
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let outputImage = context.createCGImage(
            ciImage,
            from: ciImage.extent,
            colorSpace: rgbColorSpace
        ) else {
            return nil
        }
        
        return outputImage
    }
    
    // MARK: - Normalization
    func normalizeImage(_ image: CGImage) -> CGImage? {
        let ciImage = CIImage(cgImage: image)
        let context = CIContext()
        
        // Apply normalization filters
        let normalizedImage = ciImage
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.0,
                kCIInputContrastKey: 1.2,
                kCIInputSaturationKey: 1.0
            ])
            .applyingFilter("CIUnsharpMask", parameters: [
                kCIInputRadiusKey: 2.0,
                kCIInputIntensityKey: 0.5
            ])
        
        guard let outputImage = context.createCGImage(normalizedImage, from: normalizedImage.extent) else {
            return nil
        }
        
        return outputImage
    }
    
    // MARK: - Complete Preprocessing Pipeline
    func preprocessForYOLO(_ image: CGImage) -> CGImage? {
        // Step 1: Convert to RGB
        guard let rgbImage = convertToRGB(image) else {
            print("Failed to convert to RGB")
            return nil
        }
        
        // Step 2: Preprocess (resize, pad)
        guard let preprocessedImage = preprocessImage(rgbImage, targetSize: targetSize) else {
            print("Failed to preprocess image")
            return nil
        }
        
        // Step 3: Normalize
        guard let normalizedImage = normalizeImage(preprocessedImage) else {
            print("Failed to normalize image")
            return nil
        }
        
        return normalizedImage
    }
    
    // MARK: - Coordinate Transformation
    func transformCoordinates(
        detection: Detection,
        originalImageSize: CGSize,
        preprocessedImageSize: CGSize
    ) -> Detection {
        // Calculate scaling factors
        let scaleX = originalImageSize.width / preprocessedImageSize.width
        let scaleY = originalImageSize.height / preprocessedImageSize.height
        
        // Calculate padding
        let paddingX = (preprocessedImageSize.width - originalImageSize.width * preprocessedImageSize.height / originalImageSize.height) / 2
        let paddingY = (preprocessedImageSize.height - originalImageSize.height * preprocessedImageSize.width / originalImageSize.width) / 2
        
        // Transform bounding box coordinates
        let transformedBox = CGRect(
            x: (detection.boundingBox.x - paddingX / preprocessedImageSize.width) * scaleX,
            y: (detection.boundingBox.y - paddingY / preprocessedImageSize.height) * scaleY,
            width: detection.boundingBox.width * scaleX,
            height: detection.boundingBox.height * scaleY
        )
        
        // Ensure coordinates are within bounds
        let clampedBox = CGRect(
            x: max(0, min(1, transformedBox.x)),
            y: max(0, min(1, transformedBox.y)),
            width: max(0, min(1, transformedBox.width)),
            height: max(0, min(1, transformedBox.height))
        )
        
        return Detection(
            label: detection.label,
            confidence: detection.confidence,
            boundingBox: clampedBox
        )
    }
    
    // MARK: - Image Quality Assessment
    func assessImageQuality(_ image: CGImage) -> ImageQualityAssessment {
        let ciImage = CIImage(cgImage: image)
        
        // Calculate sharpness using Laplacian variance
        let sharpness = calculateSharpness(ciImage)
        
        // Calculate brightness
        let brightness = calculateBrightness(ciImage)
        
        // Calculate contrast
        let contrast = calculateContrast(ciImage)
        
        // Calculate overall quality score
        let qualityScore = (sharpness + brightness + contrast) / 3.0
        
        return ImageQualityAssessment(
            sharpness: sharpness,
            brightness: brightness,
            contrast: contrast,
            overallScore: qualityScore,
            isSuitable: qualityScore > 0.6
        )
    }
    
    private func calculateSharpness(_ image: CIImage) -> Double {
        let context = CIContext()
        
        // Apply Laplacian filter
        let laplacianFilter = CIFilter(name: "CILaplacian")!
        laplacianFilter.setValue(image, forKey: kCIInputImageKey)
        
        guard let outputImage = laplacianFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return 0.0
        }
        
        // Calculate variance of the Laplacian
        let data = cgImage.dataProvider?.data
        let bytes = CFDataGetBytePtr(data)
        let length = CFDataGetLength(data)
        
        guard let bytes = bytes, length > 0 else { return 0.0 }
        
        var sum: Double = 0
        var sumSquared: Double = 0
        let pixelCount = length / 4 // Assuming RGBA
        
        for i in 0..<pixelCount {
            let pixelValue = Double(bytes[i * 4]) // Use red channel
            sum += pixelValue
            sumSquared += pixelValue * pixelValue
        }
        
        let mean = sum / Double(pixelCount)
        let variance = (sumSquared / Double(pixelCount)) - (mean * mean)
        
        return min(1.0, variance / 1000.0) // Normalize to 0-1 range
    }
    
    private func calculateBrightness(_ image: CIImage) -> Double {
        let context = CIContext()
        
        // Apply average filter
        let averageFilter = CIFilter(name: "CIAreaAverage")!
        averageFilter.setValue(image, forKey: kCIInputImageKey)
        averageFilter.setValue(CIVector(cgRect: image.extent), forKey: kCIInputExtentKey)
        
        guard let outputImage = averageFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 1, height: 1)) else {
            return 0.0
        }
        
        let data = cgImage.dataProvider?.data
        let bytes = CFDataGetBytePtr(data)
        
        guard let bytes = bytes else { return 0.0 }
        
        // Calculate average brightness
        let red = Double(bytes[0])
        let green = Double(bytes[1])
        let blue = Double(bytes[2])
        
        let brightness = (red + green + blue) / (3.0 * 255.0)
        
        // Ideal brightness is around 0.5 (middle gray)
        return 1.0 - abs(brightness - 0.5) * 2.0
    }
    
    private func calculateContrast(_ image: CIImage) -> Double {
        let context = CIContext()
        
        // Apply contrast filter
        let contrastFilter = CIFilter(name: "CIColorControls")!
        contrastFilter.setValue(image, forKey: kCIInputImageKey)
        contrastFilter.setValue(2.0, forKey: kCIInputContrastKey)
        
        guard let outputImage = contrastFilter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return 0.0
        }
        
        // Calculate standard deviation of pixel values
        let data = cgImage.dataProvider?.data
        let bytes = CFDataGetBytePtr(data)
        let length = CFDataGetLength(data)
        
        guard let bytes = bytes, length > 0 else { return 0.0 }
        
        var sum: Double = 0
        var sumSquared: Double = 0
        let pixelCount = length / 4 // Assuming RGBA
        
        for i in 0..<pixelCount {
            let pixelValue = Double(bytes[i * 4]) // Use red channel
            sum += pixelValue
            sumSquared += pixelValue * pixelValue
        }
        
        let mean = sum / Double(pixelCount)
        let variance = (sumSquared / Double(pixelCount)) - (mean * mean)
        let standardDeviation = sqrt(variance)
        
        return min(1.0, standardDeviation / 100.0) // Normalize to 0-1 range
    }
}

// MARK: - Supporting Types
struct ImageQualityAssessment {
    let sharpness: Double
    let brightness: Double
    let contrast: Double
    let overallScore: Double
    let isSuitable: Bool
    
    var qualityLevel: QualityLevel {
        switch overallScore {
        case 0.8...1.0:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        default:
            return .poor
        }
    }
}

enum QualityLevel: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var color: String {
        switch self {
        case .excellent:
            return "green"
        case .good:
            return "blue"
        case .fair:
            return "yellow"
        case .poor:
            return "red"
        }
    }
}

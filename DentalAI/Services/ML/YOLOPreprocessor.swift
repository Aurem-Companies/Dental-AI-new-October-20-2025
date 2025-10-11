import Foundation
import UIKit
import CoreImage
import CoreGraphics
import Accelerate

// MARK: - YOLO Preprocessor
class YOLOPreprocessor {
    
    // MARK: - Properties
    private let targetSize: CGSize = CGSize(width: 416, height: 416)
    private let context = CIContext()
    
    // MARK: - Image Preprocessing
    func preprocessImage(_ image: UIImage) throws -> Data {
        // Step 1: Resize image to target size
        let resizedImage = try resizeImage(image, to: targetSize)
        
        // Step 2: Convert to RGB format
        let rgbImage = try convertToRGB(resizedImage)
        
        // Step 3: Normalize pixel values
        let normalizedImage = try normalizeImage(rgbImage)
        
        // Step 4: Convert to tensor format
        let tensorData = try convertToTensor(normalizedImage)
        
        return tensorData
    }
    
    // MARK: - Image Resizing
    private func resizeImage(_ image: UIImage, to size: CGSize) throws -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        
        guard let cgImage = resizedImage.cgImage else {
            throw PreprocessingError.imageResizeFailed
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // MARK: - RGB Conversion
    private func convertToRGB(_ image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw PreprocessingError.imageConversionFailed
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
        // Convert to RGB color space
        let rgbFilter = CIFilter(name: "CIColorMatrix")!
        rgbFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        // RGB conversion matrix
        let rgbMatrix = CIVector(x: 1, y: 0, z: 0, w: 0)
        rgbFilter.setValue(rgbMatrix, forKey: "inputRVector")
        
        let greenMatrix = CIVector(x: 0, y: 1, z: 0, w: 0)
        rgbFilter.setValue(greenMatrix, forKey: "inputGVector")
        
        let blueMatrix = CIVector(x: 0, y: 0, z: 1, w: 0)
        rgbFilter.setValue(blueMatrix, forKey: "inputBVector")
        
        let alphaMatrix = CIVector(x: 0, y: 0, z: 0, w: 1)
        rgbFilter.setValue(alphaMatrix, forKey: "inputAVector")
        
        guard let outputImage = rgbFilter.outputImage else {
            throw PreprocessingError.imageConversionFailed
        }
        
        guard let outputCGImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            throw PreprocessingError.imageConversionFailed
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - Image Normalization
    private func normalizeImage(_ image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw PreprocessingError.imageNormalizationFailed
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            throw PreprocessingError.imageNormalizationFailed
        }
        
        // Create normalized image data
        var normalizedBytes = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let normalizedIndex = y * width * bytesPerPixel + x * bytesPerPixel
                
                // Normalize to 0-1 range
                let r = Float(bytes[pixelIndex]) / 255.0
                let g = Float(bytes[pixelIndex + 1]) / 255.0
                let b = Float(bytes[pixelIndex + 2]) / 255.0
                let a = Float(bytes[pixelIndex + 3]) / 255.0
                
                // Convert back to 0-255 range
                normalizedBytes[normalizedIndex] = UInt8(r * 255)
                normalizedBytes[normalizedIndex + 1] = UInt8(g * 255)
                normalizedBytes[normalizedIndex + 2] = UInt8(b * 255)
                normalizedBytes[normalizedIndex + 3] = UInt8(a * 255)
            }
        }
        
        // Create CGImage from normalized data
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let dataProvider = CGDataProvider(data: Data(normalizedBytes) as CFData),
              let normalizedCGImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * bytesPerPixel,
                space: colorSpace,
                bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
                provider: dataProvider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            throw PreprocessingError.imageNormalizationFailed
        }
        
        return UIImage(cgImage: normalizedCGImage)
    }
    
    // MARK: - Tensor Conversion
    private func convertToTensor(_ image: UIImage) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw PreprocessingError.tensorConversionFailed
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            throw PreprocessingError.tensorConversionFailed
        }
        
        // Create tensor data (CHW format: Channels, Height, Width)
        var tensorData = [Float](repeating: 0, count: 3 * height * width)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                
                // Extract RGB values
                let r = Float(bytes[pixelIndex]) / 255.0
                let g = Float(bytes[pixelIndex + 1]) / 255.0
                let b = Float(bytes[pixelIndex + 2]) / 255.0
                
                // Store in CHW format
                let tensorIndex = y * width + x
                tensorData[tensorIndex] = r                    // Red channel
                tensorData[height * width + tensorIndex] = g  // Green channel
                tensorData[2 * height * width + tensorIndex] = b // Blue channel
            }
        }
        
        // Convert to Data
        return Data(bytes: tensorData, count: tensorData.count * MemoryLayout<Float>.size)
    }
    
    // MARK: - Post-processing
    func postprocessOutputs(_ outputs: [Float], imageSize: CGSize) throws -> [Detection] {
        let numDetections = 25200 // YOLOv8 default
        let numClasses = 10 // Number of dental conditions
        let numAnchors = 3
        
        var detections: [Detection] = []
        
        for i in 0..<numDetections {
            let baseIndex = i * (5 + numClasses) // x, y, w, h, confidence + class scores
            
            // Extract bounding box coordinates
            let x = outputs[baseIndex]
            let y = outputs[baseIndex + 1]
            let w = outputs[baseIndex + 2]
            let h = outputs[baseIndex + 3]
            let confidence = outputs[baseIndex + 4]
            
            // Skip low confidence detections
            guard confidence > 0.5 else { continue }
            
            // Find best class
            var bestClassIndex = 0
            var bestClassScore = outputs[baseIndex + 5]
            
            for classIndex in 1..<numClasses {
                let classScore = outputs[baseIndex + 5 + classIndex]
                if classScore > bestClassScore {
                    bestClassScore = classScore
                    bestClassIndex = classIndex
                }
            }
            
            // Calculate final confidence
            let finalConfidence = confidence * bestClassScore
            
            // Skip low confidence detections
            guard finalConfidence > 0.3 else { continue }
            
            // Convert to image coordinates
            let imageWidth = Float(imageSize.width)
            let imageHeight = Float(imageSize.height)
            
            let centerX = x * imageWidth
            let centerY = y * imageHeight
            let width = w * imageWidth
            let height = h * imageHeight
            
            let boundingBox = CGRect(
                x: CGFloat(centerX - width / 2),
                y: CGFloat(centerY - height / 2),
                width: CGFloat(width),
                height: CGFloat(height)
            )
            
            // Map class index to condition
            let condition = mapClassIndexToCondition(bestClassIndex)
            
            let detection = Detection(
                label: condition,
                confidence: finalConfidence,
                boundingBox: boundingBox
            )
            
            detections.append(detection)
        }
        
        // Apply Non-Maximum Suppression
        return applyNMS(detections)
    }
    
    // MARK: - Class Index Mapping
    private func mapClassIndexToCondition(_ classIndex: Int) -> String {
        switch classIndex {
        case 0: return "cavity"
        case 1: return "gingivitis"
        case 2: return "discoloration"
        case 3: return "plaque"
        case 4: return "tartar"
        case 5: return "dead_tooth"
        case 6: return "root_canal"
        case 7: return "chipped"
        case 8: return "misaligned"
        case 9: return "healthy"
        default: return "unknown"
        }
    }
    
    // MARK: - Non-Maximum Suppression
    private func applyNMS(_ detections: [Detection]) -> [Detection] {
        guard !detections.isEmpty else { return [] }
        
        // Sort by confidence
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var selectedDetections: [Detection] = []
        var suppressedIndices: Set<Int> = []
        
        for (index, detection) in sortedDetections.enumerated() {
            if suppressedIndices.contains(index) { continue }
            
            selectedDetections.append(detection)
            
            // Suppress overlapping detections
            for (otherIndex, otherDetection) in sortedDetections.enumerated() {
                if otherIndex <= index || suppressedIndices.contains(otherIndex) { continue }
                
                let iou = calculateIoU(detection.boundingBox, otherDetection.boundingBox)
                if iou > 0.4 { // NMS threshold
                    suppressedIndices.insert(otherIndex)
                }
            }
        }
        
        return selectedDetections
    }
    
    // MARK: - IoU Calculation
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let intersectionArea = intersection.width * intersection.height
        
        let box1Area = box1.width * box1.height
        let box2Area = box2.width * box2.height
        let unionArea = box1Area + box2Area - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
    
    // MARK: - Image Enhancement
    func enhanceImage(_ image: UIImage) throws -> UIImage {
        guard let cgImage = image.cgImage else {
            throw PreprocessingError.imageEnhancementFailed
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        
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
        
        guard let outputCGImage = context.createCGImage(enhancedImage, from: enhancedImage.extent) else {
            throw PreprocessingError.imageEnhancementFailed
        }
        
        return UIImage(cgImage: outputCGImage)
    }
    
    // MARK: - Quality Assessment
    func assessImageQuality(_ image: UIImage) -> ImageQuality {
        guard let cgImage = image.cgImage else {
            return ImageQuality(
                sharpness: 0.0,
                brightness: 0.0,
                contrast: 0.0,
                blur: 1.0,
                overallScore: 0.0,
                qualityLevel: .poor
            )
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return ImageQuality(
                sharpness: 0.0,
                brightness: 0.0,
                contrast: 0.0,
                blur: 1.0,
                overallScore: 0.0,
                qualityLevel: .poor
            )
        }
        
        // Calculate image quality metrics
        let sharpness = calculateSharpness(bytes: bytes, width: width, height: height, bytesPerRow: bytesPerRow)
        let brightness = calculateBrightness(bytes: bytes, width: width, height: height, bytesPerRow: bytesPerRow)
        let contrast = calculateContrast(bytes: bytes, width: width, height: height, bytesPerRow: bytesPerRow)
        let blur = calculateBlur(bytes: bytes, width: width, height: height, bytesPerRow: bytesPerRow)
        
        let overallScore = (sharpness + brightness + contrast + (1.0 - blur)) / 4.0
        let qualityLevel = determineQualityLevel(overallScore)
        
        return ImageQuality(
            sharpness: sharpness,
            brightness: brightness,
            contrast: contrast,
            blur: blur,
            overallScore: overallScore,
            qualityLevel: qualityLevel
        )
    }
    
    // MARK: - Quality Calculation Methods
    private func calculateSharpness(bytes: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) -> Float {
        var laplacianSum: Float = 0.0
        var laplacianSquaredSum: Float = 0.0
        let count = Float((width - 2) * (height - 2))
        
        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let center = Float(bytes[pixelIndex])
                let top = Float(bytes[(y - 1) * bytesPerRow + x * bytesPerPixel])
                let bottom = Float(bytes[(y + 1) * bytesPerRow + x * bytesPerPixel])
                let left = Float(bytes[y * bytesPerRow + (x - 1) * bytesPerPixel])
                let right = Float(bytes[y * bytesPerRow + (x + 1) * bytesPerPixel])
                
                let laplacian = abs(4 * center - top - bottom - left - right)
                laplacianSum += laplacian
                laplacianSquaredSum += laplacian * laplacian
            }
        }
        
        let mean = laplacianSum / count
        let variance = (laplacianSquaredSum / count) - (mean * mean)
        
        return min(1.0, max(0.0, variance / 1000.0))
    }
    
    private func calculateBrightness(bytes: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) -> Float {
        var totalBrightness: Float = 0.0
        let pixelCount = Float(width * height)
        
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let r = Float(bytes[pixelIndex])
                let g = Float(bytes[pixelIndex + 1])
                let b = Float(bytes[pixelIndex + 2])
                
                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                totalBrightness += brightness
            }
        }
        
        return totalBrightness / pixelCount / 255.0
    }
    
    private func calculateContrast(bytes: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) -> Float {
        var grayPixels: [Float] = []
        
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
        
        let mean = grayPixels.reduce(0, +) / Float(grayPixels.count)
        let variance = grayPixels.map { pow($0 - mean, 2) }.reduce(0, +) / Float(grayPixels.count)
        let standardDeviation = sqrt(variance)
        
        return standardDeviation / 128.0
    }
    
    private func calculateBlur(bytes: UnsafePointer<UInt8>, width: Int, height: Int, bytesPerRow: Int) -> Float {
        var gradientSum: Float = 0.0
        let count = Float((width - 1) * (height - 1))
        
        for y in 0..<(height - 1) {
            for x in 0..<(width - 1) {
                let pixelIndex = y * bytesPerRow + x * bytesPerPixel
                let current = Float(bytes[pixelIndex])
                let right = Float(bytes[y * bytesPerRow + (x + 1) * bytesPerPixel])
                let bottom = Float(bytes[(y + 1) * bytesPerRow + x * bytesPerPixel])
                
                let gradientX = right - current
                let gradientY = bottom - current
                let magnitude = sqrt(gradientX * gradientX + gradientY * gradientY)
                
                gradientSum += magnitude
            }
        }
        
        let averageGradient = gradientSum / count
        return min(1.0, max(0.0, 1.0 - (averageGradient / 50.0)))
    }
    
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
}

// MARK: - Preprocessing Error
enum PreprocessingError: Error, LocalizedError {
    case imageResizeFailed
    case imageConversionFailed
    case imageNormalizationFailed
    case tensorConversionFailed
    case imageEnhancementFailed
    case postprocessingFailed
    
    var errorDescription: String? {
        switch self {
        case .imageResizeFailed:
            return "Failed to resize image"
        case .imageConversionFailed:
            return "Failed to convert image format"
        case .imageNormalizationFailed:
            return "Failed to normalize image"
        case .tensorConversionFailed:
            return "Failed to convert to tensor format"
        case .imageEnhancementFailed:
            return "Failed to enhance image"
        case .postprocessingFailed:
            return "Failed to postprocess outputs"
        }
    }
}
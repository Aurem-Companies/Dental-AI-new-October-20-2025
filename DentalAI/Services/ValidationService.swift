import Foundation
import UIKit
import Vision
import CoreImage

// MARK: - Validation Service
class ValidationService {
    
    // MARK: - Properties
    private let minImageSize: CGSize = CGSize(width: 224, height: 224)
    private let maxImageSize: CGSize = CGSize(width: 4096, height: 4096)
    private let minQualityThreshold: Float = 0.4
    private let minTeethAreaRatio: Float = 0.1
    
    // MARK: - Image Validation
    func validateImage(_ image: UIImage) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        
        // Check image size
        if image.size.width < minImageSize.width || image.size.height < minImageSize.height {
            errors.append(.imageTooSmall)
        }
        
        if image.size.width > maxImageSize.width || image.size.height > maxImageSize.height {
            errors.append(.imageTooLarge)
        }
        
        // Check image format
        guard image.cgImage != nil else {
            errors.append(.unsupportedFormat)
            return ValidationResult(isValid: false, errors: errors, warnings: warnings)
        }
        
        // Check image quality
        let quality = assessImageQuality(image)
        if quality.overallScore < minQualityThreshold {
            errors.append(.poorQuality)
        }
        
        // Check for teeth detection
        let teethDetection = detectTeethInImage(image)
        if teethDetection.confidence < 0.3 {
            errors.append(.noTeethDetected)
        }
        
        // Check lighting conditions
        let lighting = assessLighting(image)
        if lighting.isPoorLighting {
            warnings.append("Poor lighting detected. Results may be less accurate.")
        }
        
        // Check for blur
        if quality.blur > 0.7 {
            errors.append(.imageTooBlurry)
        }
        
        let isValid = errors.isEmpty
        return ValidationResult(isValid: isValid, errors: errors, warnings: warnings)
    }
    
    // MARK: - User Profile Validation
    func validateUserProfile(_ profile: UserProfile) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        
        // Check age
        if let age = profile.age {
            if age < 0 || age > 150 {
                errors.append(.validationFailed)
                warnings.append("Invalid age provided")
            }
        }
        
        // Check preferences
        if !profile.preferences.notificationsEnabled {
            warnings.append("Notifications disabled")
        }
        
        // Check analysis history
        if profile.dentalHistory.isEmpty {
            warnings.append("No analysis history available")
        }
        
        let isValid = errors.isEmpty
        return ValidationResult(isValid: isValid, errors: errors, warnings: warnings)
    }
    
    // MARK: - Analysis Result Validation
    func validateAnalysisResult(_ result: DentalAnalysisResult) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [String] = []
        
        // Check health score
        if result.healthScore < 0 || result.healthScore > 100 {
            errors.append(.validationFailed)
            warnings.append("Invalid health score")
        }
        
        // Check confidence
        if result.confidence < 0.0 || result.confidence > 1.0 {
            errors.append(.validationFailed)
            warnings.append("Invalid confidence score")
        }
        
        // Check detected conditions
        for (condition, confidence) in result.detectedConditions {
            if confidence < 0.0 || confidence > 1.0 {
                errors.append(.validationFailed)
                warnings.append("Invalid confidence for \(condition.displayName)")
            }
        }
        
        // Check timestamp
        if result.timestamp > Date() {
            errors.append(.validationFailed)
            warnings.append("Future timestamp detected")
        }
        
        let isValid = errors.isEmpty
        return ValidationResult(isValid: isValid, errors: errors, warnings: warnings)
    }
    
    // MARK: - Image Quality Assessment
    private func assessImageQuality(_ image: UIImage) -> ImageQuality {
        let processor = ImageProcessor()
        return processor.assessImageQuality(image)
    }
    
    // MARK: - Teeth Detection
    private func detectTeethInImage(_ image: UIImage) -> DentalValidationResult {
        guard let cgImage = image.cgImage else {
            return DentalValidationResult(confidence: 0.0, teethCount: 0, framing: .poor, lighting: .poor)
        }
        
        // Use Vision framework for teeth detection
        let request = VNDetectRectanglesRequest { request, error in
            // Handle results
        }
        
        request.minimumAspectRatio = 0.1
        request.maximumAspectRatio = 1.0
        request.minimumSize = 0.1
        request.maximumObservations = 10
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            if let observations = request.results {
                let teethCount = observations.count
                let confidence = observations.map { $0.confidence }.reduce(0, +) / Float(observations.count)
                
                return DentalValidationResult(
                    confidence: confidence,
                    teethCount: teethCount,
                    framing: assessFraming(image, observations: observations),
                    lighting: assessLighting(image)
                )
            }
        } catch {
            print("Teeth detection failed: \(error)")
        }
        
        return DentalValidationResult(confidence: 0.0, teethCount: 0, framing: .poor, lighting: .poor)
    }
    
    // MARK: - Framing Assessment
    private func assessFraming(_ image: UIImage, observations: [VNRectangleObservation]) -> FramingAssessment {
        let imageArea = image.size.width * image.size.height
        var teethArea: Float = 0.0
        
        for observation in observations {
            let rect = observation.boundingBox
            let area = Float(rect.width * rect.height) * Float(imageArea)
            teethArea += area
        }
        
        let teethAreaRatio = teethArea / Float(imageArea)
        
        if teethAreaRatio > 0.3 {
            return .excellent
        } else if teethAreaRatio > 0.2 {
            return .good
        } else if teethAreaRatio > 0.1 {
            return .fair
        } else {
            return .poor
        }
    }
    
    // MARK: - Lighting Assessment
    private func assessLighting(_ image: UIImage) -> LightingAssessment {
        let processor = ImageProcessor()
        let quality = processor.assessImageQuality(image)
        
        if quality.brightness > 0.7 && quality.contrast > 0.5 {
            return .excellent
        } else if quality.brightness > 0.5 && quality.contrast > 0.3 {
            return .good
        } else if quality.brightness > 0.3 && quality.contrast > 0.2 {
            return .fair
        } else {
            return .poor
        }
    }
    
    // MARK: - Real-time Validation
    func validateImageInRealTime(_ image: UIImage) -> RealTimeValidationResult {
        let quality = assessImageQuality(image)
        let lighting = assessLighting(image)
        let framing = assessFraming(image, observations: [])
        
        var suggestions: [String] = []
        
        // Generate suggestions based on quality
        if quality.brightness < 0.4 {
            suggestions.append("Increase lighting for better results")
        }
        
        if quality.contrast < 0.3 {
            suggestions.append("Improve contrast by adjusting lighting angle")
        }
        
        if quality.blur > 0.6 {
            suggestions.append("Hold the camera steady to reduce blur")
        }
        
        if quality.sharpness < 0.4 {
            suggestions.append("Move closer to the teeth for better focus")
        }
        
        return RealTimeValidationResult(
            quality: quality,
            lighting: lighting,
            framing: framing,
            suggestions: suggestions,
            isReadyForAnalysis: quality.overallScore > minQualityThreshold
        )
    }
    
    // MARK: - Data Integrity Validation
    func validateDataIntegrity() -> DataIntegrityResult {
        var issues: [String] = []
        var recommendations: [String] = []
        
        // Check UserDefaults
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "userProfile") == nil {
            issues.append("User profile not found")
            recommendations.append("Create a new user profile")
        }
        
        // Check Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageDirectory = documentsPath.appendingPathComponent("DentalImages")
        
        if !FileManager.default.fileExists(atPath: imageDirectory.path) {
            issues.append("Image directory not found")
            recommendations.append("Create image directory")
        }
        
        // Check for corrupted files
        if let imageFiles = try? FileManager.default.contentsOfDirectory(at: imageDirectory, includingPropertiesForKeys: nil) {
            for file in imageFiles {
                if file.pathExtension.lowercased() == "jpg" || file.pathExtension.lowercased() == "png" {
                    if let image = UIImage(contentsOfFile: file.path) {
                        if image.size.width == 0 || image.size.height == 0 {
                            issues.append("Corrupted image file: \(file.lastPathComponent)")
                            recommendations.append("Remove corrupted file")
                        }
                    }
                }
            }
        }
        
        return DataIntegrityResult(
            hasIssues: !issues.isEmpty,
            issues: issues,
            recommendations: recommendations
        )
    }
    
    // MARK: - Generate Suggestions
    func generateSuggestions(for result: ValidationResult) -> [String] {
        var suggestions: [String] = []
        
        for error in result.errors {
            switch error {
            case .imageTooSmall:
                suggestions.append("Use a higher resolution image (minimum 224x224 pixels)")
            case .imageTooLarge:
                suggestions.append("Use a smaller image (maximum 4096x4096 pixels)")
            case .unsupportedFormat:
                suggestions.append("Use JPEG or PNG format")
            case .poorQuality:
                suggestions.append("Use a clearer image with good lighting")
            case .noTeethDetected:
                suggestions.append("Ensure teeth are clearly visible in the image")
            case .lightingTooPoor:
                suggestions.append("Use better lighting or move to a brighter area")
            case .imageTooBlurry:
                suggestions.append("Hold the camera steady and ensure good focus")
            case .validationFailed:
                suggestions.append("Check your input data and try again")
            }
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [String]
    
    var hasErrors: Bool {
        return !errors.isEmpty
    }
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}

struct DentalValidationResult {
    let confidence: Float
    let teethCount: Int
    let framing: FramingAssessment
    let lighting: LightingAssessment
}

enum FramingAssessment: String, CaseIterable {
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
}

enum LightingAssessment: String, CaseIterable {
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
    
    var isPoorLighting: Bool {
        return self == .poor
    }
}

struct RealTimeValidationResult {
    let quality: ImageQuality
    let lighting: LightingAssessment
    let framing: FramingAssessment
    let suggestions: [String]
    let isReadyForAnalysis: Bool
}

struct DataIntegrityResult {
    let hasIssues: Bool
    let issues: [String]
    let recommendations: [String]
}

// MARK: - Image Quality Extension
extension ValidationService {
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
                
                let brightness = 0.299 * r + 0.587 * g + 0.114 * b
                totalBrightness += brightness
            }
        }
        
        return totalBrightness / pixelCount / 255.0
    }
    
    private func calculateContrast(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 0.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 0.0 }
        
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
    
    private func calculateBlur(_ image: UIImage) -> Float {
        guard let cgImage = image.cgImage else { return 1.0 }
        
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else { return 1.0 }
        
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
        return min(1.0, max(0.0, 1.0 - (averageGradient / 50.0)))
    }
}
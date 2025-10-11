import UIKit
import Foundation

class ValidationService: ObservableObject {
    
    // MARK: - Image Validation
    func validateImage(_ image: UIImage) -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check image size
        let size = image.size
        if size.width < 500 || size.height < 500 {
            issues.append("Image resolution too low (minimum 500x500 pixels)")
        }
        
        // Check image quality
        let quality = assessImageQuality(image)
        if quality.poor {
            issues.append(contentsOf: quality.issues)
        }
        
        // Check for common issues
        if let brightness = calculateBrightness(image) {
            if brightness < 0.2 {
                issues.append("Image too dark for accurate analysis")
            } else if brightness > 0.9 {
                issues.append("Image too bright, may cause overexposure")
            }
        }
        
        if let contrast = calculateContrast(image) {
            if contrast < 0.1 {
                issues.append("Low contrast, may affect analysis accuracy")
            }
        }
        
        if let blur = calculateBlur(image) {
            if blur > 0.6 {
                issues.append("Image appears blurry, may affect analysis accuracy")
            } else if blur > 0.4 {
                warnings.append("Image is slightly blurry, consider retaking")
            }
        }
        
        // Check for dental-specific issues
        let dentalIssues = validateDentalImage(image)
        issues.append(contentsOf: dentalIssues.issues)
        warnings.append(contentsOf: dentalIssues.warnings)
        
        let isValid = issues.isEmpty
        let severity: ValidationSeverity = issues.isEmpty ? (warnings.isEmpty ? .none : .warning) : .error
        
        return ValidationResult(
            isValid: isValid,
            severity: severity,
            issues: issues,
            warnings: warnings,
            suggestions: generateSuggestions(issues: issues, warnings: warnings)
        )
    }
    
    // MARK: - User Input Validation
    func validateUserProfile(_ profile: UserProfile) -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Validate name
        if profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("Name cannot be empty")
        } else if profile.name.count < 2 {
            issues.append("Name must be at least 2 characters long")
        } else if profile.name.count > 50 {
            issues.append("Name cannot exceed 50 characters")
        }
        
        // Validate age
        if profile.age < 0 {
            issues.append("Age cannot be negative")
        } else if profile.age > 150 {
            issues.append("Age appears to be invalid")
        } else if profile.age < 5 {
            warnings.append("App is designed for users 5 years and older")
        }
        
        // Validate dental history
        if profile.dentalHistory.count > 100 {
            warnings.append("Large number of analysis results may affect app performance")
        }
        
        let isValid = issues.isEmpty
        let severity: ValidationSeverity = issues.isEmpty ? (warnings.isEmpty ? .none : .warning) : .error
        
        return ValidationResult(
            isValid: isValid,
            severity: severity,
            issues: issues,
            warnings: warnings,
            suggestions: generateUserProfileSuggestions(issues: issues, warnings: warnings)
        )
    }
    
    // MARK: - Analysis Result Validation
    func validateAnalysisResult(_ result: DentalAnalysisResult) -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Validate confidence
        if result.confidence < 0.0 || result.confidence > 1.0 {
            issues.append("Invalid confidence value")
        } else if result.confidence < 0.3 {
            warnings.append("Low confidence in analysis results")
        }
        
        // Validate conditions
        if result.conditions.isEmpty {
            issues.append("No conditions detected")
        } else if result.conditions.count > 10 {
            warnings.append("Unusually high number of conditions detected")
        }
        
        // Validate health score
        if result.overallHealthScore < 0 || result.overallHealthScore > 100 {
            issues.append("Invalid health score")
        }
        
        // Validate recommendations
        if result.recommendations.isEmpty {
            warnings.append("No recommendations generated")
        }
        
        // Validate timestamp
        let timeSinceAnalysis = Date().timeIntervalSince(result.timestamp)
        if timeSinceAnalysis < 0 {
            issues.append("Invalid analysis timestamp")
        } else if timeSinceAnalysis > 86400 * 30 { // 30 days
            warnings.append("Analysis result is older than 30 days")
        }
        
        let isValid = issues.isEmpty
        let severity: ValidationSeverity = issues.isEmpty ? (warnings.isEmpty ? .none : .warning) : .error
        
        return ValidationResult(
            isValid: isValid,
            severity: severity,
            issues: issues,
            warnings: warnings,
            suggestions: generateAnalysisSuggestions(issues: issues, warnings: warnings)
        )
    }
    
    // MARK: - Private Helper Methods
    private func assessImageQuality(_ image: UIImage) -> ImageQuality {
        // This would use the ImageProcessor's quality assessment
        // For now, return a basic assessment
        return ImageQuality(poor: false, issues: [])
    }
    
    private func calculateBrightness(_ image: UIImage) -> Double? {
        // This would use the ImageProcessor's brightness calculation
        // For now, return a placeholder
        return 0.5
    }
    
    private func calculateContrast(_ image: UIImage) -> Double? {
        // This would use the ImageProcessor's contrast calculation
        // For now, return a placeholder
        return 0.3
    }
    
    private func calculateBlur(_ image: UIImage) -> Double? {
        // This would use the ImageProcessor's blur calculation
        // For now, return a placeholder
        return 0.2
    }
    
    private func validateDentalImage(_ image: UIImage) -> DentalValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check if image appears to contain teeth
        // This is a simplified check - in reality, you'd use more sophisticated computer vision
        let hasTeeth = detectTeethInImage(image)
        if !hasTeeth {
            issues.append("No teeth detected in image")
        }
        
        // Check for proper framing
        let framing = assessImageFraming(image)
        if !framing.isGood {
            issues.append(contentsOf: framing.issues)
            warnings.append(contentsOf: framing.warnings)
        }
        
        // Check for lighting issues
        let lighting = assessLighting(image)
        if !lighting.isGood {
            warnings.append(contentsOf: lighting.warnings)
        }
        
        return DentalValidationResult(
            issues: issues,
            warnings: warnings,
            hasTeeth: hasTeeth,
            framing: framing,
            lighting: lighting
        )
    }
    
    private func detectTeethInImage(_ image: UIImage) -> Bool {
        // Simplified teeth detection
        // In a real implementation, this would use computer vision
        return true // Placeholder
    }
    
    private func assessImageFraming(_ image: UIImage) -> FramingAssessment {
        // Simplified framing assessment
        // In a real implementation, this would analyze the image composition
        return FramingAssessment(
            isGood: true,
            issues: [],
            warnings: []
        )
    }
    
    private func assessLighting(_ image: UIImage) -> LightingAssessment {
        // Simplified lighting assessment
        // In a real implementation, this would analyze lighting conditions
        return LightingAssessment(
            isGood: true,
            warnings: []
        )
    }
    
    private func generateSuggestions(issues: [String], warnings: [String]) -> [String] {
        var suggestions: [String] = []
        
        if issues.contains(where: { $0.contains("resolution") }) {
            suggestions.append("Use a higher resolution camera or move closer to your teeth")
        }
        
        if issues.contains(where: { $0.contains("dark") }) {
            suggestions.append("Ensure good lighting when taking the photo")
        }
        
        if issues.contains(where: { $0.contains("bright") }) {
            suggestions.append("Avoid direct light or flash that may cause overexposure")
        }
        
        if issues.contains(where: { $0.contains("blurry") }) {
            suggestions.append("Hold the camera steady and ensure focus is on your teeth")
        }
        
        if issues.contains(where: { $0.contains("contrast") }) {
            suggestions.append("Ensure good contrast between teeth and background")
        }
        
        if warnings.contains(where: { $0.contains("blurry") }) {
            suggestions.append("Consider retaking the photo for better clarity")
        }
        
        return suggestions
    }
    
    private func generateUserProfileSuggestions(issues: [String], warnings: [String]) -> [String] {
        var suggestions: [String] = []
        
        if issues.contains(where: { $0.contains("Name") }) {
            suggestions.append("Enter a valid name between 2 and 50 characters")
        }
        
        if issues.contains(where: { $0.contains("Age") }) {
            suggestions.append("Enter a valid age between 0 and 150 years")
        }
        
        if warnings.contains(where: { $0.contains("5 years") }) {
            suggestions.append("Consider consulting with a pediatric dentist")
        }
        
        return suggestions
    }
    
    private func generateAnalysisSuggestions(issues: [String], warnings: [String]) -> [String] {
        var suggestions: [String] = []
        
        if issues.contains(where: { $0.contains("confidence") }) {
            suggestions.append("Retake the photo with better lighting and focus")
        }
        
        if issues.contains(where: { $0.contains("conditions") }) {
            suggestions.append("Ensure the image clearly shows your teeth")
        }
        
        if warnings.contains(where: { $0.contains("Low confidence") }) {
            suggestions.append("Consider retaking the photo for more accurate analysis")
        }
        
        if warnings.contains(where: { $0.contains("recommendations") }) {
            suggestions.append("Contact a dental professional for personalized advice")
        }
        
        return suggestions
    }
}

// MARK: - Supporting Types
struct ValidationResult {
    let isValid: Bool
    let severity: ValidationSeverity
    let issues: [String]
    let warnings: [String]
    let suggestions: [String]
    
    var hasIssues: Bool { !issues.isEmpty }
    var hasWarnings: Bool { !warnings.isEmpty }
    var hasSuggestions: Bool { !suggestions.isEmpty }
}

enum ValidationSeverity {
    case none
    case warning
    case error
    
    var color: String {
        switch self {
        case .none: return "green"
        case .warning: return "yellow"
        case .error: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }
}

struct DentalValidationResult {
    let issues: [String]
    let warnings: [String]
    let hasTeeth: Bool
    let framing: FramingAssessment
    let lighting: LightingAssessment
}

struct FramingAssessment {
    let isGood: Bool
    let issues: [String]
    let warnings: [String]
}

struct LightingAssessment {
    let isGood: Bool
    let warnings: [String]
}

// MARK: - Validation Extensions
extension ValidationService {
    
    // MARK: - Real-time Validation
    func validateImageInRealTime(_ image: UIImage) -> ValidationResult {
        // Simplified real-time validation for performance
        var issues: [String] = []
        var warnings: [String] = []
        
        // Quick size check
        let size = image.size
        if size.width < 300 || size.height < 300 {
            issues.append("Image too small")
        }
        
        // Quick quality check
        if let brightness = calculateBrightness(image) {
            if brightness < 0.1 || brightness > 0.95 {
                issues.append("Poor lighting conditions")
            }
        }
        
        let isValid = issues.isEmpty
        let severity: ValidationSeverity = issues.isEmpty ? (warnings.isEmpty ? .none : .warning) : .error
        
        return ValidationResult(
            isValid: isValid,
            severity: severity,
            issues: issues,
            warnings: warnings,
            suggestions: generateSuggestions(issues: issues, warnings: warnings)
        )
    }
    
    // MARK: - Poor Lighting Detection
    func detectPoorLightingConditions(_ image: UIImage) -> PoorLightingAnalysis {
        var conditions: [PoorLightingCondition] = []
        var severity: PoorLightingSeverity = .good
        
        // Check brightness
        if let brightness = calculateBrightness(image) {
            if brightness < 0.1 {
                conditions.append(.tooDark)
                severity = .poor
            } else if brightness > 0.9 {
                conditions.append(.tooBright)
                severity = .poor
            } else if brightness < 0.2 || brightness > 0.8 {
                conditions.append(.suboptimal)
                severity = .fair
            }
        }
        
        // Check contrast
        if let contrast = calculateContrast(image) {
            if contrast < 0.1 {
                conditions.append(.lowContrast)
                severity = .poor
            } else if contrast < 0.2 {
                conditions.append(.suboptimal)
                severity = .fair
            }
        }
        
        // Check for specific lighting issues
        if detectHarshShadows(image) {
            conditions.append(.harshShadows)
            severity = .fair
        }
        
        if detectOverexposure(image) {
            conditions.append(.overexposed)
            severity = .poor
        }
        
        if detectUnderexposure(image) {
            conditions.append(.underexposed)
            severity = .poor
        }
        
        return PoorLightingAnalysis(
            conditions: conditions,
            severity: severity,
            recommendations: generateLightingRecommendations(conditions: conditions)
        )
    }
    
    private func detectHarshShadows(_ image: UIImage) -> Bool {
        // Simplified shadow detection
        // In a real implementation, this would use more sophisticated computer vision
        if let brightness = calculateBrightness(image) {
            return brightness < 0.3 || brightness > 0.7
        }
        return false
    }
    
    private func detectOverexposure(_ image: UIImage) -> Bool {
        // Simplified overexposure detection
        if let brightness = calculateBrightness(image) {
            return brightness > 0.9
        }
        return false
    }
    
    private func detectUnderexposure(_ image: UIImage) -> Bool {
        // Simplified underexposure detection
        if let brightness = calculateBrightness(image) {
            return brightness < 0.1
        }
        return false
    }
    
    private func generateLightingRecommendations(conditions: [PoorLightingCondition]) -> [String] {
        var recommendations: [String] = []
        
        for condition in conditions {
            switch condition {
            case .tooDark:
                recommendations.append("Move to a brighter area or turn on more lights")
            case .tooBright:
                recommendations.append("Move to a shaded area or reduce lighting")
            case .lowContrast:
                recommendations.append("Ensure good contrast between teeth and background")
            case .harshShadows:
                recommendations.append("Use diffused lighting to reduce shadows")
            case .overexposed:
                recommendations.append("Avoid direct light or flash")
            case .underexposed:
                recommendations.append("Increase lighting or move closer to light source")
            case .suboptimal:
                recommendations.append("Adjust lighting for better image quality")
            }
        }
        
        return recommendations
    }
    
    // MARK: - Batch Validation
    func validateAnalysisHistory(_ history: [DentalAnalysisResult]) -> [ValidationResult] {
        return history.map { validateAnalysisResult($0) }
    }
    
    // MARK: - Data Integrity Validation
    func validateDataIntegrity() -> ValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Check for data consistency
        let dataManager = DataManager.shared
        let dataIssues = dataManager.validateData()
        
        if !dataIssues.isEmpty {
            issues.append(contentsOf: dataIssues)
        }
        
        // Check for storage issues
        let storageInfo = getStorageInfo()
        if storageInfo.usedSpace > storageInfo.totalSpace * 0.9 {
            warnings.append("Storage space is running low")
        }
        
        let isValid = issues.isEmpty
        let severity: ValidationSeverity = issues.isEmpty ? (warnings.isEmpty ? .none : .warning) : .error
        
        return ValidationResult(
            isValid: isValid,
            severity: severity,
            issues: issues,
            warnings: warnings,
            suggestions: generateDataIntegritySuggestions(issues: issues, warnings: warnings)
        )
    }
    
    private func getStorageInfo() -> StorageInfo {
        // Simplified storage info
        return StorageInfo(usedSpace: 100, totalSpace: 1000)
    }
    
    private func generateDataIntegritySuggestions(issues: [String], warnings: [String]) -> [String] {
        var suggestions: [String] = []
        
        if issues.contains(where: { $0.contains("orphaned") }) {
            suggestions.append("Run data repair to clean up orphaned files")
        }
        
        if issues.contains(where: { $0.contains("Missing") }) {
            suggestions.append("Some analysis images may be missing")
        }
        
        if warnings.contains(where: { $0.contains("Storage") }) {
            suggestions.append("Consider clearing old analysis results to free up space")
        }
        
        return suggestions
    }
}

struct StorageInfo {
    let usedSpace: Int64
    let totalSpace: Int64
}

// MARK: - Poor Lighting Analysis Types
struct PoorLightingAnalysis {
    let conditions: [PoorLightingCondition]
    let severity: PoorLightingSeverity
    let recommendations: [String]
    
    var hasIssues: Bool {
        !conditions.isEmpty
    }
    
    var isPoor: Bool {
        severity == .poor
    }
}

enum PoorLightingCondition: String, CaseIterable {
    case tooDark = "Too Dark"
    case tooBright = "Too Bright"
    case lowContrast = "Low Contrast"
    case harshShadows = "Harsh Shadows"
    case overexposed = "Overexposed"
    case underexposed = "Underexposed"
    case suboptimal = "Suboptimal"
    
    var description: String {
        switch self {
        case .tooDark:
            return "Image is too dark for accurate analysis"
        case .tooBright:
            return "Image is too bright, may cause overexposure"
        case .lowContrast:
            return "Low contrast between teeth and background"
        case .harshShadows:
            return "Harsh shadows affecting image quality"
        case .overexposed:
            return "Image is overexposed, details may be lost"
        case .underexposed:
            return "Image is underexposed, details may be lost"
        case .suboptimal:
            return "Lighting conditions are suboptimal"
        }
    }
}

enum PoorLightingSeverity: String, CaseIterable {
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    var color: String {
        switch self {
        case .good:
            return "green"
        case .fair:
            return "yellow"
        case .poor:
            return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .good:
            return "checkmark.circle.fill"
        case .fair:
            return "exclamationmark.triangle.fill"
        case .poor:
            return "xmark.circle.fill"
        }
    }
}

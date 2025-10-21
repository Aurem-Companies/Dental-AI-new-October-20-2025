import Foundation
import UIKit
import CoreImage
import Vision
import CoreGraphics
import Accelerate

// MARK: - Image Normalization Extension
extension UIImage {
    /// Normalizes orientation and returns BGRA sRGB CGImage.
    func normalizedCGImage() -> CGImage? {
        // Fix orientation by redrawing
        let size = self.size
        let renderer = UIGraphicsImageRenderer(size: size)
        let fixed = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let cg = fixed.cgImage else { return nil }

        // Ensure sRGB colorspace and BGRA pixel format if needed (Vision tolerant, ONNX often wants BGRA)
        return cg
    }
}

// MARK: - Dental Analysis Engine
class DentalAnalysisEngine {
    
    // MARK: - Properties
    private let imageProcessor = ImageProcessor()
    private let validationService = ValidationService()
    private let recommendationEngine = RecommendationEngine()
    private let dataManager = DataManager.shared
    
    // MARK: - Main Analysis Pipeline
    func analyzeDentalImage(_ image: UIImage, userProfile: UserProfile) async throws -> DentalAnalysisResult {
        print("🔬 DentalAnalysisEngine: Starting analysis pipeline...")
        let startTime = Date()
        
        // Step 1: Validate & normalize
        print("🔬 DentalAnalysisEngine: Step 1 - Validating & normalizing image...")
        guard let cg = image.normalizedCGImage() else {
            print("🔬 DentalAnalysisEngine: Image normalization failed")
            throw AnalysisError.invalidImage
        }
        
        // Optional size gate: reject tiny captures that break downstream
        let w = cg.width, h = cg.height
        guard w >= 256, h >= 256 else {
            print("🔬 DentalAnalysisEngine: Image too small (\(w)x\(h))")
            throw AnalysisError.invalidImage
        }
        
        print("🔬 DentalAnalysisEngine: Image validation & normalization passed")
        
        // Step 2: Preprocess image
        let preprocessStart = Date()
        guard let preprocessedImage = imageProcessor.enhanceImage(image) else {
            throw AnalysisError.processingFailed
        }
        let preprocessTime = Date().timeIntervalSince(preprocessStart)
        
        // Step 3: Detect dental conditions
        print("🔬 DentalAnalysisEngine: Step 3 - Detecting dental conditions...")
        let detectionStart = Date()
        let detectedConditions = try await detectDentalConditions(preprocessedImage)
        let detectionTime = Date().timeIntervalSince(detectionStart)
        print("🔬 DentalAnalysisEngine: Detection completed - found \(detectedConditions.count) conditions")
        
        // Step 4: Post-process results
        let postprocessStart = Date()
        let healthScore = calculateHealthScore(detectedConditions)
        let confidence = calculateOverallConfidence(detectedConditions)
        let postprocessTime = Date().timeIntervalSince(postprocessStart)
        
        // Step 5: Generate recommendations
        let recommendations = recommendationEngine.generatePersonalizedRecommendations(
            for: DentalAnalysisResult(
                healthScore: healthScore,
                detectedConditions: detectedConditions,
                timestamp: Date(),
                imageURL: nil,
                analysisDuration: Date().timeIntervalSince(startTime),
                confidence: confidence,
                recommendations: [],
                metadata: AnalysisMetadata(
                    imageSize: image.size,
                    processingMethod: "ML",
                    modelVersion: "1.0",
                    deviceInfo: "iOS",
                    preprocessingTime: preprocessTime,
                    inferenceTime: detectionTime,
                    postprocessingTime: postprocessTime
                )
            ),
            userProfile: userProfile
        )
        
        // Step 6: Create final result
        let result = DentalAnalysisResult(
            healthScore: healthScore,
            detectedConditions: detectedConditions,
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: Date().timeIntervalSince(startTime),
            confidence: confidence,
            recommendations: recommendations,
            metadata: AnalysisMetadata(
                imageSize: image.size,
                processingMethod: "ML",
                modelVersion: "1.0",
                deviceInfo: "iOS",
                preprocessingTime: preprocessTime,
                inferenceTime: detectionTime,
                postprocessingTime: postprocessTime
            )
        )
        
        print("🔬 DentalAnalysisEngine: Analysis pipeline completed successfully")
        print("🔬 DentalAnalysisEngine: Final result - Health Score: \(result.healthScore), Conditions: \(result.detectedConditions.count)")
        return result
    }
    
    // MARK: - Dental Condition Detection
    private func detectDentalConditions(_ image: UIImage) async throws -> [DentalCondition: Double] {
        var detectedConditions: [DentalCondition: Double] = [:]
        
        // Pull effective flags and choose detection backend(s)
        let flags = FeatureFlags.current
        RuntimeChecks.validateFlags(flags)

        // Build preferred order from flags (ONNX → ML → CV when enabled)
        var preferred: [DetectionBackend] = []
        if flags.useONNXDetection { preferred.append(.onnx) }
        if flags.useMLDetection { preferred.append(.ml) }

        // CV is the safety net; include it if explicitly enabled OR if fallback is enabled
        if flags.useCVDetection || flags.enableFallback {
            preferred.append(.cv)
        }

        // Absolute guard: never run without any backend listed
        if preferred.isEmpty { preferred = [.cv] }

        // Create service
        let detector = DetectionFactory.make(preferred: preferred)
        
        // Use the detection service
        do {
            detectedConditions = try await detectConditionsByML(image, detector: detector)
        } catch {
            print("Detection failed, falling back to rule-based detection: \(error)")
            if flags.enableFallback {
                detectedConditions = try await detectConditionsByRules(image)
            } else {
                throw error
            }
        }
        
        return detectedConditions
    }
    
    // MARK: - ML-Based Detection
    private func detectConditionsByML(_ image: UIImage, detector: DetectionService) async throws -> [DentalCondition: Double] {
        // This would integrate with the actual ML model
        // For now, we'll simulate ML detection
        
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        let detections = try detector.detect(in: cgImage)
        
        var conditions: [DentalCondition: Double] = [:]
        
        for detection in detections {
            if let condition = DentalCondition(rawValue: detection.label) {
                conditions[condition] = Double(detection.confidence)
            }
        }
        
        // If no conditions detected, assume healthy
        if conditions.isEmpty {
            conditions[.healthy] = 0.8
        }
        
        return conditions
    }
    
    // MARK: - Rule-Based Detection
    private func detectConditionsByRules(_ image: UIImage) async throws -> [DentalCondition: Double] {
        var conditions: [DentalCondition: Double] = [:]
        
        // Analyze image quality
        let quality = imageProcessor.assessImageQuality(image)
        
        // Analyze tooth color
        let colorAnalysis = imageProcessor.analyzeToothColor(image)
        
        // Analyze edges
        let edgeAnalysis = imageProcessor.detectEdges(image)
        
        // Rule-based condition detection
        conditions = try await analyzeImageFeatures(
            quality: quality,
            colorAnalysis: colorAnalysis,
            edgeAnalysis: edgeAnalysis,
            image: image
        )
        
        return conditions
    }
    
    // MARK: - Feature Analysis
    private func analyzeImageFeatures(
        quality: ImageQuality,
        colorAnalysis: ToothColorAnalysis,
        edgeAnalysis: EdgeAnalysis,
        image: UIImage
    ) async throws -> [DentalCondition: Double] {
        var conditions: [DentalCondition: Double] = [:]
        
        // Analyze tooth color for discoloration
        if colorAnalysis.color == .yellow || colorAnalysis.color == .darkYellow {
            conditions[.discoloration] = Double(colorAnalysis.confidence)
        }
        
        // Analyze color for cavities (dark spots)
        if colorAnalysis.color == .brown {
            conditions[.cavity] = Double(colorAnalysis.confidence)
        }
        
        // Analyze healthiness for overall health
        if colorAnalysis.healthiness > 0.8 {
            conditions[.healthy] = Double(colorAnalysis.healthiness)
        }
        
        // Analyze edges for chipped teeth
        if edgeAnalysis.edgeCount > 1000 && edgeAnalysis.edgeStrength > 100 {
            conditions[.chippedTeeth] = Double(edgeAnalysis.confidence)
        }
        
        // Analyze quality for plaque detection
        if quality.sharpness < 0.3 {
            conditions[.plaque] = 0.6
        }
        
        // Analyze brightness for tartar detection
        if quality.brightness < 0.4 {
            conditions[.tartar] = 0.5
        }
        
        // Analyze contrast for gingivitis detection
        if quality.contrast < 0.3 {
            conditions[.gingivitis] = 0.4
        }
        
        // If no conditions detected, assume healthy
        if conditions.isEmpty {
            conditions[.healthy] = 0.7
        }
        
        return conditions
    }
    
    // MARK: - Health Score Calculation
    private func calculateHealthScore(_ conditions: [DentalCondition: Double]) -> Int {
        var score = 100
        
        for (condition, confidence) in conditions {
            let impact = getConditionImpact(condition)
            let weightedImpact = impact * confidence
            score -= Int(weightedImpact * 100)
        }
        
        return max(0, min(100, score))
    }
    
    private func getConditionImpact(_ condition: DentalCondition) -> Double {
        switch condition {
        case .cavity: return 0.3
        case .gingivitis: return 0.25
        case .discoloration: return 0.1
        case .plaque: return 0.15
        case .tartar: return 0.2
        case .deadTooth: return 0.4
        case .rootCanal: return 0.35
        case .chippedTeeth: return 0.2
        case .misalignedTeeth: return 0.15
        case .healthy: return -0.1 // Positive impact
        }
    }
    
    // MARK: - Confidence Calculation
    private func calculateOverallConfidence(_ conditions: [DentalCondition: Double]) -> Double {
        guard !conditions.isEmpty else { return 0.0 }
        
        let totalConfidence = conditions.values.reduce(0, +)
        let averageConfidence = totalConfidence / Double(conditions.count)
        
        // Adjust confidence based on number of conditions detected
        let conditionCount = Double(conditions.count)
        let adjustmentFactor = min(1.0, 1.0 - (conditionCount - 1) * 0.1)
        
        return averageConfidence * adjustmentFactor
    }
    
    // MARK: - Advanced Analysis Methods
    private func analyzeEdges(_ image: UIImage) -> EdgeAnalysis {
        return imageProcessor.detectEdges(image)
    }
    
    private func analyzeTexture(_ image: UIImage) -> TextureAnalysis {
        // Analyze texture patterns for gum health
        let quality = imageProcessor.assessImageQuality(image)
        
        return TextureAnalysis(
            smoothness: quality.sharpness,
            uniformity: quality.contrast,
            pattern: "regular",
            confidence: quality.overallScore
        )
    }
    
    // MARK: - Severity Assessment
    private func assessOverallSeverity(_ conditions: [DentalCondition: Double]) -> SeverityLevel {
        var maxSeverity: SeverityLevel = .none
        
        for (condition, confidence) in conditions {
            if confidence > 0.7 {
                let conditionSeverity = condition.severity
                if conditionSeverity.rawValue > maxSeverity.rawValue {
                    maxSeverity = conditionSeverity
                }
            }
        }
        
        return maxSeverity
    }
    
    // MARK: - Performance Monitoring
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let result = try await operation()
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            
            // Cancel after timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                continuation.resume(throwing: AnalysisError.processingFailed)
            }
        }
    }
    
    // MARK: - Batch Analysis
    func analyzeMultipleImages(_ images: [UIImage], userProfile: UserProfile) async throws -> [DentalAnalysisResult] {
        var results: [DentalAnalysisResult] = []
        
        for image in images {
            do {
                let result = try await analyzeDentalImage(image, userProfile: userProfile)
                results.append(result)
            } catch {
                print("Failed to analyze image: \(error)")
                // Continue with other images
            }
        }
        
        return results
    }
    
    // MARK: - Analysis History Integration
    func analyzeWithHistory(_ image: UIImage, userProfile: UserProfile) async throws -> DentalAnalysisResult {
        let result = try await analyzeDentalImage(image, userProfile: userProfile)
        
        // Add to analysis history
        dataManager.addAnalysisResult(result)
        
        return result
    }
    
    // MARK: - Real-time Analysis
    func analyzeInRealTime(_ image: UIImage) async throws -> RealTimeAnalysisResult {
        let validation = validationService.validateImageInRealTime(image)
        
        if !validation.isReadyForAnalysis {
            return RealTimeAnalysisResult(
                isReady: false,
                quality: validation.quality,
                suggestions: validation.suggestions,
                confidence: 0.0
            )
        }
        
        // Perform quick analysis
        let quality = imageProcessor.assessImageQuality(image)
        let colorAnalysis = imageProcessor.analyzeToothColor(image)
        
        let confidence = (quality.overallScore + colorAnalysis.confidence) / 2.0
        
        return RealTimeAnalysisResult(
            isReady: true,
            quality: quality,
            suggestions: [],
            confidence: confidence
        )
    }
}

// MARK: - Supporting Types
struct TextureAnalysis {
    let smoothness: Float
    let uniformity: Float
    let pattern: String
    let confidence: Float
}

struct RealTimeAnalysisResult {
    let isReady: Bool
    let quality: ImageQuality
    let suggestions: [String]
    let confidence: Float
}

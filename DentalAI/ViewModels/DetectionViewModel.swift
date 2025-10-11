import Foundation
import SwiftUI
import CoreGraphics

// MARK: - Detection View Model
@MainActor
class DetectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var analysisResult: DentalAnalysisResult?
    @Published var errorMessage: String?
    @Published var detections: [Detection] = []
    @Published var selectedDetectionService: DetectionService?
    
    // MARK: - Private Properties
    private let detectionFactory = DetectionFactory()
    private let dataManager = DataManager()
    
    // MARK: - Initialization
    init() {
        configureFeatureFlags()
        setupDetectionService()
    }
    
    // MARK: - Configuration
    private func configureFeatureFlags() {
        FeatureFlags.configureDefaults()
        
        if FeatureFlags.isDevelopment {
            FeatureFlags.configureForEnvironment()
        }
    }
    
    private func setupDetectionService() {
        selectedDetectionService = detectionFactory.make()
        
        if FeatureFlags.debugMode {
            print("Detection service configured: \(DetectionFactory.getServiceInfo(selectedDetectionService!))")
        }
    }
    
    // MARK: - Analysis Methods
    func analyzeImage(_ image: UIImage) async {
        guard let cgImage = image.cgImage else {
            await handleError("Invalid image format")
            return
        }
        
        await performAnalysis(cgImage: cgImage, originalImage: image)
    }
    
    private func performAnalysis(cgImage: CGImage, originalImage: UIImage) async {
        isAnalyzing = true
        errorMessage = nil
        
        do {
            // Perform detection
            let detections = try await performDetection(cgImage: cgImage)
            
            // Convert detections to dental conditions
            let conditions = convertDetectionsToConditions(detections)
            
            // Generate recommendations
            let recommendations = generateRecommendations(for: conditions)
            
            // Create analysis result
            let result = DentalAnalysisResult(
                conditions: conditions,
                confidence: calculateOverallConfidence(detections),
                severity: calculateOverallSeverity(conditions),
                recommendations: recommendations,
                timestamp: Date(),
                image: originalImage
            )
            
            // Save result
            await saveAnalysisResult(result)
            
            // Update UI
            self.analysisResult = result
            self.detections = detections
            
        } catch {
            await handleError("Analysis failed: \(error.localizedDescription)")
        }
        
        isAnalyzing = false
    }
    
    private func performDetection(cgImage: CGImage) async throws -> [Detection] {
        guard let service = selectedDetectionService else {
            throw ModelError.modelUnavailable
        }
        
        if #available(iOS 13.0, *) {
            if let mlService = service as? MLDetectionService {
                return try await mlService.detectAsync(in: cgImage)
            } else if let cvService = service as? CVDentitionService {
                return try await cvService.detectAsync(in: cgImage)
            }
        }
        
        // Fallback to synchronous detection
        return try service.detect(in: cgImage)
    }
    
    // MARK: - Detection Processing
    private func convertDetectionsToConditions(_ detections: [Detection]) -> [DentalCondition] {
        var conditions: [DentalCondition] = []
        
        for detection in detections {
            let condition = mapDetectionToCondition(detection)
            if !conditions.contains(condition) {
                conditions.append(condition)
            }
        }
        
        // If no conditions detected, assume healthy
        if conditions.isEmpty {
            conditions.append(.healthy)
        }
        
        return conditions
    }
    
    private func mapDetectionToCondition(_ detection: Detection) -> DentalCondition {
        let label = detection.label.lowercased()
        
        // Map detection labels to dental conditions
        switch label {
        case "cavity", "tooth_decay", "decay":
            return .cavity
        case "gingivitis", "gum_disease", "gum_inflammation":
            return .gingivitis
        case "discoloration", "staining", "yellowing":
            return .discoloration
        case "plaque", "bacterial_film":
            return .plaque
        case "tartar", "calculus", "hardened_plaque":
            return .tartar
        case "dead_tooth", "non_vital":
            return .deadTooth
        case "chipped", "fractured", "broken":
            return .chipped
        case "misaligned", "crooked", "malocclusion":
            return .misaligned
        case "tooth", "dental_region", "tooth_structure":
            return .healthy
        default:
            return .healthy
        }
    }
    
    private func calculateOverallConfidence(_ detections: [Detection]) -> Double {
        guard !detections.isEmpty else { return 0.0 }
        
        let totalConfidence = detections.reduce(0.0) { total, detection in
            total + Double(detection.confidence)
        }
        
        return totalConfidence / Double(detections.count)
    }
    
    private func calculateOverallSeverity(_ conditions: [DentalCondition]) -> SeverityLevel {
        guard !conditions.isEmpty else { return .none }
        
        let severities = conditions.map { $0.severity }
        
        // Return the highest severity level
        if severities.contains(.high) {
            return .high
        } else if severities.contains(.medium) {
            return .medium
        } else if severities.contains(.low) {
            return .low
        } else {
            return .none
        }
    }
    
    // MARK: - Recommendations
    private func generateRecommendations(for conditions: [DentalCondition]) -> [Recommendation] {
        var recommendations: [Recommendation] = []
        
        for condition in conditions {
            let conditionRecommendations = generateRecommendationsForCondition(condition)
            recommendations.append(contentsOf: conditionRecommendations)
        }
        
        // Add general recommendations
        recommendations.append(contentsOf: generateGeneralRecommendations())
        
        return recommendations
    }
    
    private func generateRecommendationsForCondition(_ condition: DentalCondition) -> [Recommendation] {
        switch condition {
        case .cavity:
            return [
                Recommendation(
                    title: "Schedule Dental Appointment",
                    description: "Cavities require professional treatment to prevent further decay.",
                    priority: .immediate,
                    category: .professional,
                    actionItems: ["Call your dentist", "Avoid sugary foods", "Use fluoride toothpaste"]
                )
            ]
        case .gingivitis:
            return [
                Recommendation(
                    title: "Improve Oral Hygiene",
                    description: "Gingivitis can be reversed with proper brushing and flossing.",
                    priority: .urgent,
                    category: .homeCare,
                    actionItems: ["Brush twice daily", "Floss daily", "Use antiseptic mouthwash"]
                )
            ]
        case .discoloration:
            return [
                Recommendation(
                    title: "Teeth Whitening Options",
                    description: "Consider professional whitening or over-the-counter products.",
                    priority: .important,
                    category: .products,
                    actionItems: ["Consult dentist", "Try whitening toothpaste", "Limit staining foods"]
                )
            ]
        case .plaque:
            return [
                Recommendation(
                    title: "Enhanced Brushing Technique",
                    description: "Focus on thorough brushing to remove plaque buildup.",
                    priority: .important,
                    category: .homeCare,
                    actionItems: ["Brush for 2 minutes", "Use soft-bristled brush", "Replace brush every 3 months"]
                )
            ]
        case .tartar:
            return [
                Recommendation(
                    title: "Professional Cleaning",
                    description: "Tartar removal requires professional dental cleaning.",
                    priority: .urgent,
                    category: .professional,
                    actionItems: ["Schedule cleaning", "Maintain regular hygiene", "Use tartar-control toothpaste"]
                )
            ]
        case .deadTooth:
            return [
                Recommendation(
                    title: "Immediate Dental Care",
                    description: "Dead teeth require prompt professional treatment.",
                    priority: .immediate,
                    category: .emergency,
                    actionItems: ["Call dentist immediately", "Avoid chewing on affected side", "Take pain medication if needed"]
                )
            ]
        case .chipped:
            return [
                Recommendation(
                    title: "Dental Restoration",
                    description: "Chipped teeth may need restoration to prevent further damage.",
                    priority: .urgent,
                    category: .professional,
                    actionItems: ["Schedule appointment", "Avoid hard foods", "Use mouthguard if needed"]
                )
            ]
        case .misaligned:
            return [
                Recommendation(
                    title: "Orthodontic Consultation",
                    description: "Consider orthodontic treatment for alignment issues.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Consult orthodontist", "Consider braces or aligners", "Maintain oral hygiene"]
                )
            ]
        case .healthy:
            return [
                Recommendation(
                    title: "Maintain Good Oral Health",
                    description: "Continue your current oral hygiene routine.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: ["Brush twice daily", "Floss daily", "Regular dental checkups"]
                )
            ]
        case .rootCanal:
            return [
                Recommendation(
                    title: "Follow-up Care",
                    description: "Root canal treatment requires proper follow-up care.",
                    priority: .important,
                    category: .professional,
                    actionItems: ["Follow dentist instructions", "Take prescribed medications", "Avoid hard foods"]
                )
            ]
        }
    }
    
    private func generateGeneralRecommendations() -> [Recommendation] {
        return [
            Recommendation(
                title: "Regular Dental Checkups",
                description: "Schedule regular dental appointments for preventive care.",
                priority: .important,
                category: .professional,
                actionItems: ["Schedule every 6 months", "Update dental history", "Ask about preventive treatments"]
            ),
            Recommendation(
                title: "Healthy Diet for Teeth",
                description: "Maintain a diet that supports dental health.",
                priority: .general,
                category: .lifestyle,
                actionItems: ["Limit sugary foods", "Eat calcium-rich foods", "Drink plenty of water"]
            )
        ]
    }
    
    // MARK: - Data Management
    private func saveAnalysisResult(_ result: DentalAnalysisResult) async {
        do {
            try await dataManager.saveAnalysisResult(result)
        } catch {
            print("Failed to save analysis result: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ message: String) async {
        errorMessage = message
        
        if FeatureFlags.debugMode {
            print("Detection error: \(message)")
        }
    }
    
    // MARK: - Service Management
    func switchDetectionService(to useML: Bool) {
        FeatureFlags.useMLDetection = useML
        setupDetectionService()
        
        if FeatureFlags.debugMode {
            print("Switched to \(useML ? "ML" : "CV") detection service")
        }
    }
    
    func refreshDetectionService() {
        setupDetectionService()
    }
    
    // MARK: - Testing Methods
    func testDetectionService() async -> Bool {
        guard let service = selectedDetectionService else { return false }
        
        // Create a test image (1x1 pixel)
        let testImage = createTestImage()
        
        do {
            _ = try service.detect(in: testImage)
            return true
        } catch {
            print("Detection service test failed: \(error.localizedDescription)")
            return false
        }
    }
    
    private func createTestImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        
        return context!.makeImage()!
    }
    
    // MARK: - Public Methods
    func clearResults() {
        analysisResult = nil
        detections = []
        errorMessage = nil
    }
    
    func getServiceStatus() -> String {
        return DetectionFactory.getServiceInfo(selectedDetectionService!)
    }
    
    func getFeatureFlagsStatus() -> String {
        return FeatureFlags.featureStatus
    }
}

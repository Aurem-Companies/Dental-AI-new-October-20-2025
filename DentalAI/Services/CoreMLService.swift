import UIKit
import CoreML
import Vision

// MARK: - Core ML Service Protocol
protocol CoreMLServiceProtocol {
    func classifyDentalConditions(_ image: UIImage) async throws -> [DentalCondition]
    func segmentTeeth(_ image: UIImage) async throws -> UIImage?
    func detectCavities(_ image: UIImage) async throws -> [CavityDetection]
    func analyzeGumHealth(_ image: UIImage) async throws -> GumHealthAnalysis
}

// MARK: - Core ML Service Implementation
class CoreMLService: ObservableObject, CoreMLServiceProtocol {
    
    // MARK: - Properties
    private var dentalClassifier: VNCoreMLModel?
    private var teethSegmenter: VNCoreMLModel?
    private var cavityDetector: VNCoreMLModel?
    private var gumAnalyzer: VNCoreMLModel?
    
    // MARK: - Initialization
    init() {
        loadModels()
    }
    
    // MARK: - Model Loading
    private func loadModels() {
        // Load pre-trained models
        // In a real implementation, these would be actual .mlmodel files
        loadDentalClassifier()
        loadTeethSegmenter()
        loadCavityDetector()
        loadGumAnalyzer()
    }
    
    private func loadDentalClassifier() {
        // Placeholder for dental condition classifier
        // This would load a trained model for classifying dental conditions
        // For now, we'll use a mock implementation
    }
    
    private func loadTeethSegmenter() {
        // Placeholder for teeth segmentation model
        // This would load a model for segmenting individual teeth
    }
    
    private func loadCavityDetector() {
        // Placeholder for cavity detection model
        // This would load a specialized model for detecting cavities
    }
    
    private func loadGumAnalyzer() {
        // Placeholder for gum health analysis model
        // This would load a model for analyzing gum health
    }
    
    // MARK: - Dental Condition Classification
    func classifyDentalConditions(_ image: UIImage) async throws -> [DentalCondition] {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AnalysisError.mlFailure("Classification failed: \(error.localizedDescription)"))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: AnalysisError.mlFailure("No classification results"))
                    return
                }
                
                // Convert observations to dental conditions
                let conditions = self.convertObservationsToConditions(observations)
                continuation.resume(returning: conditions)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AnalysisError.mlFailure("Request failed: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Teeth Segmentation
    func segmentTeeth(_ image: UIImage) async throws -> UIImage? {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AnalysisError.mlFailure("Segmentation failed: \(error.localizedDescription)"))
                    return
                }
                
                guard let observations = request.results as? [VNSaliencyImageObservation],
                      let observation = observations.first,
                      let pixelBuffer = observation.pixelBuffer else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Convert pixel buffer to UIImage
                let segmentedImage = self.convertPixelBufferToImage(pixelBuffer)
                continuation.resume(returning: segmentedImage)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AnalysisError.mlFailure("Segmentation request failed: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Cavity Detection
    func detectCavities(_ image: UIImage) async throws -> [CavityDetection] {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AnalysisError.mlFailure("Cavity detection failed: \(error.localizedDescription)"))
                    return
                }
                
                guard let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Convert observations to cavity detections
                let cavities = self.convertObservationsToCavities(observations)
                continuation.resume(returning: cavities)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AnalysisError.mlFailure("Cavity detection request failed: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Gum Health Analysis
    func analyzeGumHealth(_ image: UIImage) async throws -> GumHealthAnalysis {
        guard let cgImage = image.cgImage else {
            throw AnalysisError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNClassifyImageRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: AnalysisError.mlFailure("Gum analysis failed: \(error.localizedDescription)"))
                    return
                }
                
                guard let observations = request.results as? [VNClassificationObservation] else {
                    continuation.resume(throwing: AnalysisError.mlFailure("No gum analysis results"))
                    return
                }
                
                // Convert observations to gum health analysis
                let analysis = self.convertObservationsToGumHealth(observations)
                continuation.resume(returning: analysis)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: AnalysisError.mlFailure("Gum analysis request failed: \(error.localizedDescription)"))
            }
        }
    }
    
    // MARK: - Helper Methods
    private func convertObservationsToConditions(_ observations: [VNClassificationObservation]) -> [DentalCondition] {
        var conditions: [DentalCondition] = []
        
        for observation in observations {
            // Map classification results to dental conditions
            // This is a simplified mapping - in reality, you'd have trained models
            switch observation.identifier.lowercased() {
            case "cavity", "tooth_decay":
                conditions.append(.cavity)
            case "gingivitis", "gum_disease":
                conditions.append(.gingivitis)
            case "discoloration", "staining":
                conditions.append(.discoloration)
            case "plaque":
                conditions.append(.plaque)
            case "tartar", "calculus":
                conditions.append(.tartar)
            case "dead_tooth", "non_vital":
                conditions.append(.deadTooth)
            case "chipped", "fractured":
                conditions.append(.chipped)
            case "misaligned", "crooked":
                conditions.append(.misaligned)
            case "healthy", "normal":
                conditions.append(.healthy)
            default:
                break
            }
        }
        
        return conditions.isEmpty ? [.healthy] : conditions
    }
    
    private func convertObservationsToCavities(_ observations: [VNRectangleObservation]) -> [CavityDetection] {
        return observations.map { observation in
            CavityDetection(
                boundingBox: observation.boundingBox,
                confidence: observation.confidence,
                severity: observation.confidence > 0.8 ? .high : .medium
            )
        }
    }
    
    private func convertObservationsToGumHealth(_ observations: [VNClassificationObservation]) -> GumHealthAnalysis {
        var inflammationScore: Double = 0.0
        var bleedingScore: Double = 0.0
        var recessionScore: Double = 0.0
        
        for observation in observations {
            switch observation.identifier.lowercased() {
            case "inflammation", "swollen":
                inflammationScore = observation.confidence
            case "bleeding":
                bleedingScore = observation.confidence
            case "recession":
                recessionScore = observation.confidence
            default:
                break
            }
        }
        
        let overallHealth = 1.0 - (inflammationScore + bleedingScore + recessionScore) / 3.0
        
        return GumHealthAnalysis(
            inflammationScore: inflammationScore,
            bleedingScore: bleedingScore,
            recessionScore: recessionScore,
            overallHealth: max(0.0, min(1.0, overallHealth))
        )
    }
    
    private func convertPixelBufferToImage(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Supporting Types
struct CavityDetection {
    let boundingBox: CGRect
    let confidence: Float
    let severity: SeverityLevel
}

struct GumHealthAnalysis {
    let inflammationScore: Double
    let bleedingScore: Double
    let recessionScore: Double
    let overallHealth: Double
    
    var hasInflammation: Bool {
        inflammationScore > 0.5
    }
    
    var hasBleeding: Bool {
        bleedingScore > 0.5
    }
    
    var hasRecession: Bool {
        recessionScore > 0.5
    }
    
    var healthStatus: GumHealthStatus {
        switch overallHealth {
        case 0.8...1.0:
            return .healthy
        case 0.6..<0.8:
            return .mild
        case 0.4..<0.6:
            return .moderate
        default:
            return .severe
        }
    }
}

enum GumHealthStatus: String, CaseIterable {
    case healthy = "Healthy"
    case mild = "Mild Issues"
    case moderate = "Moderate Issues"
    case severe = "Severe Issues"
    
    var color: String {
        switch self {
        case .healthy:
            return "green"
        case .mild:
            return "yellow"
        case .moderate:
            return "orange"
        case .severe:
            return "red"
        }
    }
}

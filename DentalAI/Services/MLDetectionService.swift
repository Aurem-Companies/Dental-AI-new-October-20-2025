import Foundation
import UIKit
import CoreML
import Vision
import CoreGraphics

// MARK: - ML Detection Service
class MLDetectionService: DetectionService, @unchecked Sendable {
    
    // MARK: - Properties
    private var model: VNCoreMLModel?
    private let modelName = "DentalDetectionModel"
    private let confidenceThreshold: Float = 0.5
    private let nmsThreshold: Float = 0.4
    
    // MARK: - Model Availability (single source of truth)
    var isModelAvailable: Bool {
        return model != nil
    }
    
    var modelStatus: String {
        return isModelAvailable ? "Available" : "Not Available"
    }
    
    // MARK: - Initialization
    init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    private func loadModel() {
        // Try to load CoreML model first
        guard let modelURL = ModelLocator.bundledURL(name: modelName, ext: "mlmodel") else {
            #if DEBUG
            print("⚠️ CoreML model not found: \(modelName).mlmodel")
            #endif
            return
        }
        
        do {
            let coreMLModel = try MLModel(contentsOf: modelURL)
            model = try VNCoreMLModel(for: coreMLModel)
            #if DEBUG
            print("✅ CoreML model loaded successfully: \(modelName).mlmodel")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to load CoreML model: \(error)")
            #endif
            model = nil
        }
    }
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        guard let model = model else {
            throw ModelError.modelNotLoaded
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("Detection request failed: \(error)")
            }
        }
        
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results as? [VNRecognizedObjectObservation] else {
                return []
            }
            
            return processObservations(observations)
        } catch {
            throw ModelError.inferenceFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Observation Processing
    private func processObservations(_ observations: [VNRecognizedObjectObservation]) -> [Detection] {
        var detections: [Detection] = []
        
        for observation in observations {
            // Filter by confidence threshold
            guard observation.confidence >= confidenceThreshold else { continue }
            
            // Get the top label
            guard let topLabelObservation = observation.labels.first else { continue }
            
            let detection = Detection(
                label: topLabelObservation.identifier,
                confidence: observation.confidence,
                boundingBox: observation.boundingBox
            )
            
            detections.append(detection)
        }
        
        // Apply Non-Maximum Suppression
        return applyNMS(detections)
    }
    
    // MARK: - Non-Maximum Suppression
    private func applyNMS(_ detections: [Detection]) -> [Detection] {
        guard !detections.isEmpty else { return [] }
        
        // Sort by confidence (descending)
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
                if iou > nmsThreshold {
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
}


// MARK: - Async Detection Extension
extension MLDetectionService {
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

// MARK: - Performance Monitoring
extension MLDetectionService {
    func detectWithTiming(in image: CGImage) throws -> (detections: [Detection], timing: DetectionTiming) {
        let startTime = Date()
        
        let detections = try detect(in: image)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        let timing = DetectionTiming(
            totalDuration: duration,
            preprocessingDuration: 0.0, // Would be measured in actual implementation
            inferenceDuration: duration,
            postprocessingDuration: 0.0
        )
        
        return (detections, timing)
    }
}

// MARK: - Detection Timing
struct DetectionTiming {
    let totalDuration: TimeInterval
    let preprocessingDuration: TimeInterval
    let inferenceDuration: TimeInterval
    let postprocessingDuration: TimeInterval
}

// MARK: - Model Configuration
struct ModelConfiguration {
    let confidenceThreshold: Float
    let nmsThreshold: Float
    let inputSize: CGSize
    let outputClasses: [String]
    
    static let defaultConfiguration = ModelConfiguration(
        confidenceThreshold: 0.5,
        nmsThreshold: 0.4,
        inputSize: CGSize(width: 416, height: 416),
        outputClasses: [
            "cavity",
            "gingivitis", 
            "discoloration",
            "plaque",
            "tartar",
            "dead_tooth",
            "root_canal",
            "chipped",
            "misaligned",
            "healthy"
        ]
    )
}

// MARK: - Model Validation
extension MLDetectionService {
    func validateModel() -> ModelValidationResult {
        guard model != nil else {
            return ModelValidationResult(
                isValid: false,
                errors: ["Model not loaded"],
                warnings: []
            )
        }
        
        let errors: [String] = []
        let warnings: [String] = []
        
        // Check model input/output specifications
        // This would be implemented based on the actual model structure
        
        return ModelValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
}



// MARK: - Model Update Handler
protocol ModelUpdateHandler: AnyObject {
    func modelDidUpdate(_ model: VNCoreMLModel)
    func modelUpdateFailed(_ error: Error)
}

// MARK: - Model Manager
class ModelManager: ObservableObject {
    @Published var currentModel: VNCoreMLModel?
    @Published var managerStatus: String = "Loading..."
    @Published var isManagerAvailable: Bool = false
    
    private var updateHandlers: [ModelUpdateHandler] = []
    
    func addUpdateHandler(_ handler: ModelUpdateHandler) {
        updateHandlers.append(handler)
    }
    
    func removeUpdateHandler(_ handler: ModelUpdateHandler) {
        updateHandlers.removeAll { $0 === handler }
    }
    
    func loadModel(named modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlpackage") else {
            managerStatus = "Model not found: \(modelName)"
            isManagerAvailable = false
            return
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            let coreMLModel = try VNCoreMLModel(for: mlModel)
            
            currentModel = coreMLModel
            managerStatus = "Model loaded: \(modelName)"
            isManagerAvailable = true
            
            // Notify handlers
            updateHandlers.forEach { $0.modelDidUpdate(coreMLModel) }
        } catch {
            managerStatus = "Failed to load model: \(error.localizedDescription)"
            isManagerAvailable = false
            
            // Notify handlers
            updateHandlers.forEach { $0.modelUpdateFailed(error) }
        }
    }
    
    func reloadModel() {
        guard currentModel != nil else { return }
        // Implementation would reload the current model
    }
}
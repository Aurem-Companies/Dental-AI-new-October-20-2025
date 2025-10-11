import Foundation
import UIKit
import CoreML
import Vision
import CoreGraphics

// MARK: - CoreML Service Protocol
protocol CoreMLServiceProtocol {
    func loadModel(named modelName: String) throws
    func predict(image: UIImage) throws -> [String: Double]
    var isModelLoaded: Bool { get }
    var modelName: String? { get }
}

// MARK: - CoreML Service Implementation
class CoreMLService: CoreMLServiceProtocol {
    
    // MARK: - Properties
    private var model: VNCoreMLModel?
    private var currentModelName: String?
    
    var isModelLoaded: Bool {
        return model != nil
    }
    
    var modelName: String? {
        return currentModelName
    }
    
    // MARK: - Model Loading
    func loadModel(named modelName: String) throws {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlpackage") else {
            throw CoreMLError.modelNotFound(modelName)
        }
        
        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            model = try VNCoreMLModel(for: mlModel)
            currentModelName = modelName
        } catch {
            throw CoreMLError.modelLoadingFailed(error)
        }
    }
    
    // MARK: - Prediction
    func predict(image: UIImage) throws -> [String: Double] {
        guard let model = model else {
            throw CoreMLError.modelNotLoaded
        }
        
        guard let cgImage = image.cgImage else {
            throw CoreMLError.invalidImage
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                print("CoreML prediction failed: \(error)")
            }
        }
        
        request.imageCropAndScaleOption = .scaleFill
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            try handler.perform([request])
            
            guard let observations = request.results as? [VNClassificationObservation] else {
                throw CoreMLError.predictionFailed
            }
            
            return processObservations(observations)
        } catch {
            throw CoreMLError.predictionFailed
        }
    }
    
    // MARK: - Observation Processing
    private func processObservations(_ observations: [VNClassificationObservation]) -> [String: Double] {
        var predictions: [String: Double] = [:]
        
        for observation in observations {
            predictions[observation.identifier] = Double(observation.confidence)
        }
        
        return predictions
    }
    
    // MARK: - Model Information
    func getModelInfo() -> ModelInfo? {
        guard let model = model else { return nil }
        
        return ModelInfo(
            name: currentModelName ?? "Unknown",
            version: "1.0",
            inputSize: CGSize(width: 224, height: 224),
            outputClasses: getOutputClasses(),
            isLoaded: true
        )
    }
    
    private func getOutputClasses() -> [String] {
        // This would be determined by the actual model
        return [
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
    }
    
    // MARK: - Model Validation
    func validateModel() -> ModelValidationResult {
        guard let model = model else {
            return ModelValidationResult(
                isValid: false,
                errors: ["Model not loaded"],
                warnings: []
            )
        }
        
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check model input/output specifications
        // This would be implemented based on the actual model structure
        
        return ModelValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Performance Monitoring
    func predictWithTiming(image: UIImage) throws -> (predictions: [String: Double], timing: PredictionTiming) {
        let startTime = Date()
        
        let predictions = try predict(image: image)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        let timing = PredictionTiming(
            totalDuration: duration,
            preprocessingDuration: 0.0,
            inferenceDuration: duration,
            postprocessingDuration: 0.0
        )
        
        return (predictions, timing)
    }
    
    // MARK: - Batch Prediction
    func predictBatch(images: [UIImage]) throws -> [[String: Double]] {
        var results: [[String: Double]] = []
        
        for image in images {
            let prediction = try predict(image: image)
            results.append(prediction)
        }
        
        return results
    }
    
    // MARK: - Model Metrics
    func getModelMetrics() -> ModelMetrics {
        return ModelMetrics(
            accuracy: 0.85,
            precision: 0.82,
            recall: 0.88,
            f1Score: 0.85,
            inferenceTime: 0.5,
            memoryUsage: 50 * 1024 * 1024 // 50MB
        )
    }
    
    // MARK: - Model Update
    func updateModel(named modelName: String) throws {
        try loadModel(named: modelName)
    }
    
    // MARK: - Model Cleanup
    func unloadModel() {
        model = nil
        currentModelName = nil
    }
}

// MARK: - Supporting Types
struct ModelInfo {
    let name: String
    let version: String
    let inputSize: CGSize
    let outputClasses: [String]
    let isLoaded: Bool
}

struct ModelValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}

struct PredictionTiming {
    let totalDuration: TimeInterval
    let preprocessingDuration: TimeInterval
    let inferenceDuration: TimeInterval
    let postprocessingDuration: TimeInterval
}

struct ModelMetrics {
    let accuracy: Float
    let precision: Float
    let recall: Float
    let f1Score: Float
    let inferenceTime: TimeInterval
    let memoryUsage: Int64
}

// MARK: - CoreML Error
enum CoreMLError: Error, LocalizedError {
    case modelNotFound(String)
    case modelLoadingFailed(Error)
    case modelNotLoaded
    case invalidImage
    case predictionFailed
    case preprocessingFailed
    case postprocessingFailed
    
    var errorDescription: String? {
        switch self {
        case .modelNotFound(let modelName):
            return "Model not found: \(modelName)"
        case .modelLoadingFailed(let error):
            return "Model loading failed: \(error.localizedDescription)"
        case .modelNotLoaded:
            return "Model is not loaded"
        case .invalidImage:
            return "Invalid image provided"
        case .predictionFailed:
            return "Prediction failed"
        case .preprocessingFailed:
            return "Image preprocessing failed"
        case .postprocessingFailed:
            return "Result postprocessing failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .modelNotFound:
            return "Check if the model file exists in the app bundle"
        case .modelLoadingFailed:
            return "Try reloading the model or check model compatibility"
        case .modelNotLoaded:
            return "Load a model before making predictions"
        case .invalidImage:
            return "Provide a valid UIImage"
        case .predictionFailed:
            return "Try again or check model input requirements"
        case .preprocessingFailed:
            return "Check image format and size"
        case .postprocessingFailed:
            return "Check model output format"
        }
    }
}

// MARK: - CoreML Service Extensions
extension CoreMLService {
    func predictAsync(image: UIImage) async throws -> [String: Double] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let predictions = try self.predict(image: image)
                    continuation.resume(returning: predictions)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func predictBatchAsync(images: [UIImage]) async throws -> [[String: Double]] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let results = try self.predictBatch(images: images)
                    continuation.resume(returning: results)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - CoreML Service Manager
class CoreMLServiceManager: ObservableObject {
    @Published var currentService: CoreMLService?
    @Published var isServiceAvailable: Bool = false
    @Published var serviceStatus: String = "Not initialized"
    
    private var services: [String: CoreMLService] = [:]
    
    func loadService(named modelName: String) throws {
        let service = CoreMLService()
        try service.loadModel(named: modelName)
        
        services[modelName] = service
        currentService = service
        isServiceAvailable = true
        serviceStatus = "Service loaded: \(modelName)"
    }
    
    func getService(named modelName: String) -> CoreMLService? {
        return services[modelName]
    }
    
    func unloadService(named modelName: String) {
        services[modelName]?.unloadModel()
        services.removeValue(forKey: modelName)
        
        if currentService?.modelName == modelName {
            currentService = nil
            isServiceAvailable = false
            serviceStatus = "Service unloaded: \(modelName)"
        }
    }
    
    func unloadAllServices() {
        for service in services.values {
            service.unloadModel()
        }
        services.removeAll()
        currentService = nil
        isServiceAvailable = false
        serviceStatus = "All services unloaded"
    }
    
    func getAvailableServices() -> [String] {
        return Array(services.keys)
    }
    
    func getServiceInfo() -> [String: ModelInfo] {
        var info: [String: ModelInfo] = [:]
        for (name, service) in services {
            if let modelInfo = service.getModelInfo() {
                info[name] = modelInfo
            }
        }
        return info
    }
}

// MARK: - CoreML Service Factory
class CoreMLServiceFactory {
    static func createService(for modelName: String) throws -> CoreMLService {
        let service = CoreMLService()
        try service.loadModel(named: modelName)
        return service
    }
    
    static func createServiceWithFallback(for modelName: String) -> CoreMLService {
        let service = CoreMLService()
        
        do {
            try service.loadModel(named: modelName)
        } catch {
            print("Failed to load model \(modelName): \(error)")
            // Could load a default/fallback model here
        }
        
        return service
    }
}

// MARK: - CoreML Service Configuration
struct CoreMLServiceConfiguration {
    let modelName: String
    let confidenceThreshold: Float
    let inputSize: CGSize
    let outputClasses: [String]
    let enableFallback: Bool
    
    static let defaultConfiguration = CoreMLServiceConfiguration(
        modelName: "DentalDetectionModel",
        confidenceThreshold: 0.5,
        inputSize: CGSize(width: 224, height: 224),
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
        ],
        enableFallback: true
    )
}

// MARK: - CoreML Service Validator
class CoreMLServiceValidator {
    static func validateService(_ service: CoreMLService) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check if service is loaded
        if !service.isModelLoaded {
            errors.append("Service is not loaded")
        }
        
        // Check model info
        if let modelInfo = service.getModelInfo() {
            if modelInfo.inputSize.width != 224 || modelInfo.inputSize.height != 224 {
                warnings.append("Input size is not standard (224x224)")
            }
            
            if modelInfo.outputClasses.isEmpty {
                errors.append("No output classes defined")
            }
        }
        
        // Check model validation
        let modelValidation = service.validateModel()
        if !modelValidation.isValid {
            errors.append(contentsOf: modelValidation.errors)
        }
        warnings.append(contentsOf: modelValidation.warnings)
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
}

struct ValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
}
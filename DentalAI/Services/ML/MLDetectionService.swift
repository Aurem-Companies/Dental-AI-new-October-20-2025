import Foundation
import CoreML
import Vision
import CoreGraphics

// MARK: - ML Detection Service
class MLDetectionService: DetectionService {
    
    // MARK: - Properties
    private var model: VNCoreMLModel?
    private let modelName = "DentalDetectionModel"
    private let inputSize: CGFloat = 416.0
    private let confidenceThreshold: Float = 0.5
    private let iouThreshold: Float = 0.45
    
    // MARK: - Initialization
    init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    private func loadModel() {
        do {
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlpackage") else {
                print("Model file not found: \(modelName).mlpackage")
                return
            }
            
            let config = MLModelConfiguration()
            config.computeUnits = .all
            
            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            model = try VNCoreMLModel(for: mlModel)
            
            print("Successfully loaded ML model: \(modelName)")
        } catch {
            print("Failed to load ML model: \(error.localizedDescription)")
            model = nil
        }
    }
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        guard let model = model else {
            throw ModelError.modelUnavailable
        }
        
        // Preprocess image for YOLO
        guard let preprocessedImage = YOLOPreprocessor.shared.preprocessForYOLO(image) else {
            throw ModelError.invalidInput
        }
        
        // Perform detection on preprocessed image
        let detections = try performDetection(image: preprocessedImage, model: model)
        
        // Transform coordinates back to original image space
        let originalSize = CGSize(width: image.width, height: image.height)
        let preprocessedSize = CGSize(width: preprocessedImage.width, height: preprocessedImage.height)
        
        return detections.map { detection in
            YOLOPreprocessor.shared.transformCoordinates(
                detection: detection,
                originalImageSize: originalSize,
                preprocessedImageSize: preprocessedSize
            )
        }
    }
    
    private func performDetection(image: CGImage, model: VNCoreMLModel) throws -> [Detection] {
        return try withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    continuation.resume(throwing: ModelError.inferenceFailed(error.localizedDescription))
                    return
                }
                
                // Handle YOLO-style outputs
                let detections = self.processYOLOOutputs(request: request, originalImage: image)
                continuation.resume(returning: detections)
            }
            
            // Configure for YOLO processing
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: ModelError.inferenceFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - YOLO Processing
    private func processYOLOOutputs(request: VNRequest, originalImage: CGImage) -> [Detection] {
        var detections: [Detection] = []
        
        // Try different output formats that YOLO might produce
        if let observations = request.results as? [VNRecognizedObjectObservation] {
            // Standard Vision framework output
            detections = processStandardObservations(observations)
        } else if let mlFeatureProvider = request.results as? MLFeatureProvider {
            // Raw CoreML output - YOLO format
            detections = processYOLORawOutputs(featureProvider: mlFeatureProvider, originalImage: originalImage)
        }
        
        // Apply NMS (Non-Maximum Suppression)
        return applyNMS(detections: detections, iouThreshold: iouThreshold)
    }
    
    private func processStandardObservations(_ observations: [VNRecognizedObjectObservation]) -> [Detection] {
        return observations.compactMap { observation -> Detection? in
            guard observation.confidence > confidenceThreshold else { return nil }
            
            return Detection(
                label: observation.labels.first?.identifier ?? "Unknown",
                confidence: observation.confidence,
                boundingBox: observation.boundingBox
            )
        }
    }
    
    private func processYOLORawOutputs(featureProvider: MLFeatureProvider, originalImage: CGImage) -> [Detection] {
        var detections: [Detection] = []
        
        // YOLO typically outputs: [batch, num_detections, 5 + num_classes]
        // Format: [x, y, w, h, confidence, class1_prob, class2_prob, ...]
        
        let imageWidth = CGFloat(originalImage.width)
        let imageHeight = CGFloat(originalImage.height)
        
        // Try to find the detection output
        for featureName in featureProvider.featureNames {
            if let multiArray = featureProvider.featureValue(for: featureName)?.multiArrayValue {
                let yoloDetections = processYOLOMultiArray(
                    multiArray: multiArray,
                    imageWidth: imageWidth,
                    imageHeight: imageHeight
                )
                detections.append(contentsOf: yoloDetections)
            }
        }
        
        return detections
    }
    
    private func processYOLOMultiArray(multiArray: MLMultiArray, imageWidth: CGFloat, imageHeight: CGFloat) -> [Detection] {
        var detections: [Detection] = []
        
        // YOLO output shape: [1, num_detections, 5 + num_classes]
        let shape = multiArray.shape
        guard shape.count >= 2 else { return detections }
        
        let numDetections = shape[1].intValue
        let numFeatures = shape.count > 2 ? shape[2].intValue : 0
        
        // Dental class labels (matching the conversion script)
        let classLabels = [
            "cavity", "gingivitis", "discoloration", "plaque", "tartar",
            "dead_tooth", "chipped", "misaligned", "healthy_tooth", "gum_inflammation"
        ]
        
        for i in 0..<numDetections {
            let baseIndex = i * numFeatures
            
            // Extract bounding box (normalized coordinates)
            let centerX = CGFloat(multiArray[baseIndex].doubleValue)
            let centerY = CGFloat(multiArray[baseIndex + 1].doubleValue)
            let width = CGFloat(multiArray[baseIndex + 2].doubleValue)
            let height = CGFloat(multiArray[baseIndex + 3].doubleValue)
            let confidence = Float(multiArray[baseIndex + 4].doubleValue)
            
            guard confidence > confidenceThreshold else { continue }
            
            // Find best class
            var bestClassIndex = 0
            var bestClassScore: Float = 0
            
            for j in 5..<numFeatures {
                let classScore = Float(multiArray[baseIndex + j].doubleValue)
                if classScore > bestClassScore {
                    bestClassScore = classScore
                    bestClassIndex = j - 5
                }
            }
            
            // Convert normalized coordinates to image coordinates
            let x = (centerX - width / 2) * imageWidth
            let y = (centerY - height / 2) * imageHeight
            let w = width * imageWidth
            let h = height * imageHeight
            
            let boundingBox = CGRect(x: x, y: y, width: w, height: h)
            
            // Normalize bounding box for Vision framework (0-1 range)
            let normalizedBox = CGRect(
                x: x / imageWidth,
                y: y / imageHeight,
                width: w / imageWidth,
                height: h / imageHeight
            )
            
            let label = bestClassIndex < classLabels.count ? classLabels[bestClassIndex] : "Unknown"
            let finalConfidence = confidence * bestClassScore
            
            let detection = Detection(
                label: label,
                confidence: finalConfidence,
                boundingBox: normalizedBox
            )
            
            detections.append(detection)
        }
        
        return detections
    }
    
    // MARK: - Non-Maximum Suppression
    private func applyNMS(detections: [Detection], iouThreshold: Float) -> [Detection] {
        // Sort by confidence
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var filteredDetections: [Detection] = []
        
        for detection in sortedDetections {
            var shouldKeep = true
            
            for keptDetection in filteredDetections {
                if calculateIoU(detection.boundingBox, keptDetection.boundingBox) > iouThreshold {
                    shouldKeep = false
                    break
                }
            }
            
            if shouldKeep {
                filteredDetections.append(detection)
            }
        }
        
        return filteredDetections
    }
    
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let intersectionArea = intersection.width * intersection.height
        
        let box1Area = box1.width * box1.height
        let box2Area = box2.width * box2.height
        let unionArea = box1Area + box2Area - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
    
    // MARK: - Model Status
    var isModelAvailable: Bool {
        return model != nil
    }
    
    var modelStatus: String {
        if let model = model {
            return "Model loaded successfully"
        } else {
            return "Model not available"
        }
    }
}

// MARK: - Async/Await Support
@available(iOS 13.0, *)
extension MLDetectionService {
    func detectAsync(in image: CGImage) async throws -> [Detection] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
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

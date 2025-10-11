import Foundation
import CoreGraphics
import Accelerate

// MARK: - ONNX Detection Service
class ONNXDetectionService: DetectionService {
    
    // MARK: - Properties
    private let modelName = "dental_model"
    private let inputSize: CGFloat = 416.0
    private let confidenceThreshold: Float = 0.5
    private let iouThreshold: Float = 0.45
    
    // Dental class labels
    private let classLabels = [
        "cavity", "gingivitis", "discoloration", "plaque", "tartar",
        "dead_tooth", "chipped", "misaligned", "healthy_tooth", "gum_inflammation"
    ]
    
    // MARK: - Initialization
    init() {
        print("ONNX Detection Service initialized")
    }
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        // For now, return mock detections since we can't run ONNX inference in Swift
        // In a real implementation, you would use ONNX Runtime for iOS
        return createMockDetections(for: image)
    }
    
    // MARK: - Mock Detection (Temporary)
    private func createMockDetections(for image: CGImage) -> [Detection] {
        var detections: [Detection] = []
        
        // Create some realistic mock detections
        let imageWidth = CGFloat(image.width)
        let imageHeight = CGFloat(image.height)
        
        // Mock detection 1: Healthy tooth
        let healthyBox = CGRect(
            x: imageWidth * 0.2,
            y: imageHeight * 0.3,
            width: imageWidth * 0.6,
            height: imageHeight * 0.4
        )
        detections.append(Detection(
            label: "healthy_tooth",
            confidence: 0.85,
            boundingBox: healthyBox
        ))
        
        // Mock detection 2: Potential cavity (lower confidence)
        let cavityBox = CGRect(
            x: imageWidth * 0.3,
            y: imageHeight * 0.4,
            width: imageWidth * 0.1,
            height: imageHeight * 0.15
        )
        detections.append(Detection(
            label: "cavity",
            confidence: 0.65,
            boundingBox: cavityBox
        ))
        
        // Mock detection 3: Gingivitis
        let gingivitisBox = CGRect(
            x: imageWidth * 0.1,
            y: imageHeight * 0.7,
            width: imageWidth * 0.8,
            height: imageHeight * 0.1
        )
        detections.append(Detection(
            label: "gingivitis",
            confidence: 0.72,
            boundingBox: gingivitisBox
        ))
        
        return detections
    }
    
    // MARK: - Image Preprocessing
    private func preprocessImage(_ image: CGImage) -> [Float]? {
        // Convert CGImage to RGB data
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data,
              let bytes = CFDataGetBytePtr(data) else {
            return nil
        }
        
        let width = image.width
        let height = image.height
        let bytesPerPixel = 4 // RGBA
        let bytesPerRow = image.bytesPerRow
        
        // Resize to 416x416 and normalize
        var resizedData = [Float]()
        resizedData.reserveCapacity(3 * 416 * 416)
        
        // Simple nearest neighbor resize and normalization
        for y in 0..<416 {
            for x in 0..<416 {
                let srcX = Int(Float(x) * Float(width) / 416.0)
                let srcY = Int(Float(y) * Float(height) / 416.0)
                
                let pixelIndex = srcY * bytesPerRow + srcX * bytesPerPixel
                
                if pixelIndex < CFDataGetLength(data) - 2 {
                    let r = Float(bytes[pixelIndex]) / 255.0
                    let g = Float(bytes[pixelIndex + 1]) / 255.0
                    let b = Float(bytes[pixelIndex + 2]) / 255.0
                    
                    resizedData.append(r)
                    resizedData.append(g)
                    resizedData.append(b)
                }
            }
        }
        
        return resizedData
    }
    
    // MARK: - Post-processing
    private func processYOLOOutputs(_ outputs: [Float], imageSize: CGSize) -> [Detection] {
        // YOLO output format: [batch, 84, 3549]
        // 84 = 4 (bbox) + 80 (classes) - but we have 10 classes
        // So we need to adjust this for our 10-class model
        
        var detections: [Detection] = []
        let numDetections = 3549
        let numClasses = 10
        let numBoxParams = 4 // x, y, w, h
        
        for i in 0..<numDetections {
            let baseIndex = i * (numBoxParams + numClasses)
            
            // Extract bounding box
            let centerX = outputs[baseIndex]
            let centerY = outputs[baseIndex + 1]
            let width = outputs[baseIndex + 2]
            let height = outputs[baseIndex + 3]
            
            // Extract class scores
            var maxScore: Float = 0
            var maxClassIndex = 0
            
            for j in 0..<numClasses {
                let score = outputs[baseIndex + numBoxParams + j]
                if score > maxScore {
                    maxScore = score
                    maxClassIndex = j
                }
            }
            
            // Filter by confidence threshold
            if maxScore > confidenceThreshold {
                // Convert normalized coordinates to image coordinates
                let x = (centerX - width / 2) * Float(imageSize.width)
                let y = (centerY - height / 2) * Float(imageSize.height)
                let w = width * Float(imageSize.width)
                let h = height * Float(imageSize.height)
                
                let boundingBox = CGRect(x: CGFloat(x), y: CGFloat(y), width: CGFloat(w), height: CGFloat(h))
                
                if maxClassIndex < classLabels.count {
                    detections.append(Detection(
                        label: classLabels[maxClassIndex],
                        confidence: maxScore,
                        boundingBox: boundingBox
                    ))
                }
            }
        }
        
        // Apply Non-Maximum Suppression
        return applyNMS(detections)
    }
    
    // MARK: - Non-Maximum Suppression
    private func applyNMS(_ detections: [Detection]) -> [Detection] {
        var sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var filteredDetections: [Detection] = []
        
        while !sortedDetections.isEmpty {
            let current = sortedDetections.removeFirst()
            filteredDetections.append(current)
            
            // Remove overlapping detections
            sortedDetections = sortedDetections.filter { detection in
                calculateIoU(current.boundingBox, detection.boundingBox) < iouThreshold
            }
        }
        
        return filteredDetections
    }
    
    // MARK: - IoU Calculation
    private func calculateIoU(_ box1: CGRect, _ box2: CGRect) -> Float {
        let intersection = box1.intersection(box2)
        let intersectionArea = intersection.width * intersection.height
        let unionArea = box1.width * box1.height + box2.width * box2.height - intersectionArea
        
        return Float(intersectionArea / unionArea)
    }
}

// MARK: - Async Extension
extension ONNXDetectionService {
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

import Foundation
import CoreGraphics
import Vision

// MARK: - CV Dentition Service
class CVDentitionService: DetectionService {
    
    // MARK: - Properties
    private let confidenceThreshold: Float = 0.3
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        return try performComputerVisionDetection(image: image)
    }
    
    private func performComputerVisionDetection(image: CGImage) throws -> [Detection] {
        return try withCheckedThrowingContinuation { continuation in
            var detections: [Detection] = []
            
            // Use Vision framework for basic computer vision detection
            let requests = [
                createRectangleDetectionRequest(),
                createContourDetectionRequest(),
                createSaliencyDetectionRequest()
            ]
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            do {
                try handler.perform(requests)
                
                // Process results from different detection methods
                detections.append(contentsOf: processRectangleResults(requests[0]))
                detections.append(contentsOf: processContourResults(requests[1]))
                detections.append(contentsOf: processSaliencyResults(requests[2]))
                
                // Filter and merge overlapping detections
                let filteredDetections = filterAndMergeDetections(detections)
                
                continuation.resume(returning: filteredDetections)
            } catch {
                continuation.resume(throwing: ModelError.inferenceFailed(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Vision Requests
    private func createRectangleDetectionRequest() -> VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest { request, error in
            // Results will be processed in processRectangleResults
        }
        request.maximumObservations = 10
        request.minimumAspectRatio = 0.2
        request.maximumAspectRatio = 5.0
        return request
    }
    
    private func createContourDetectionRequest() -> VNDetectContoursRequest {
        let request = VNDetectContoursRequest { request, error in
            // Results will be processed in processContourResults
        }
        request.detectsDarkOnLight = true
        request.contrastAdjustment = 2.0
        return request
    }
    
    private func createSaliencyDetectionRequest() -> VNGenerateAttentionBasedSaliencyImageRequest {
        let request = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
            // Results will be processed in processSaliencyResults
        }
        return request
    }
    
    // MARK: - Result Processing
    private func processRectangleResults(_ request: VNDetectRectanglesRequest) -> [Detection] {
        guard let observations = request.results as? [VNRectangleObservation] else {
            return []
        }
        
        return observations.compactMap { observation -> Detection? in
            guard observation.confidence > confidenceThreshold else { return nil }
            
            // Determine if this could be a tooth based on aspect ratio and size
            let aspectRatio = observation.boundingBox.width / observation.boundingBox.height
            let isToothLike = aspectRatio > 0.3 && aspectRatio < 3.0 && observation.boundingBox.width > 0.05
            
            if isToothLike {
                return Detection(
                    label: "Tooth",
                    confidence: observation.confidence,
                    boundingBox: observation.boundingBox
                )
            }
            
            return nil
        }
    }
    
    private func processContourResults(_ request: VNDetectContoursRequest) -> [Detection] {
        guard let observations = request.results as? [VNContoursObservation] else {
            return []
        }
        
        return observations.compactMap { observation -> Detection? in
            guard observation.confidence > confidenceThreshold else { return nil }
            
            // Analyze contour shape to detect tooth-like structures
            let boundingBox = observation.boundingBox
            let aspectRatio = boundingBox.width / boundingBox.height
            let area = boundingBox.width * boundingBox.height
            
            // Heuristic: teeth are typically rectangular with moderate aspect ratios
            let isToothLike = aspectRatio > 0.4 && aspectRatio < 2.5 && area > 0.01
            
            if isToothLike {
                return Detection(
                    label: "Tooth Structure",
                    confidence: observation.confidence,
                    boundingBox: boundingBox
                )
            }
            
            return nil
        }
    }
    
    private func processSaliencyResults(_ request: VNGenerateAttentionBasedSaliencyImageRequest) -> [Detection] {
        guard let observations = request.results as? [VNSaliencyImageObservation] else {
            return []
        }
        
        return observations.compactMap { observation -> Detection? in
            guard observation.confidence > confidenceThreshold else { return nil }
            
            // Use saliency to detect areas of interest that might be teeth
            let boundingBox = observation.boundingBox
            let area = boundingBox.width * boundingBox.height
            
            // Focus on medium-sized salient regions
            if area > 0.005 && area < 0.3 {
                return Detection(
                    label: "Dental Region",
                    confidence: observation.confidence,
                    boundingBox: boundingBox
                )
            }
            
            return nil
        }
    }
    
    // MARK: - Detection Filtering
    private func filterAndMergeDetections(_ detections: [Detection]) -> [Detection] {
        // Remove low confidence detections
        let filteredDetections = detections.filter { $0.confidence > confidenceThreshold }
        
        // Merge overlapping detections
        return mergeOverlappingDetections(filteredDetections)
    }
    
    private func mergeOverlappingDetections(_ detections: [Detection]) -> [Detection] {
        var mergedDetections: [Detection] = []
        var processedIndices: Set<Int> = []
        
        for (index, detection) in detections.enumerated() {
            guard !processedIndices.contains(index) else { continue }
            
            var mergedDetection = detection
            var mergedIndices: Set<Int> = [index]
            
            // Find overlapping detections
            for (otherIndex, otherDetection) in detections.enumerated() {
                guard otherIndex != index && !processedIndices.contains(otherIndex) else { continue }
                
                if boundingBoxesOverlap(detection.boundingBox, otherDetection.boundingBox) {
                    // Merge detections by taking the one with higher confidence
                    if otherDetection.confidence > mergedDetection.confidence {
                        mergedDetection = otherDetection
                    }
                    mergedIndices.insert(otherIndex)
                }
            }
            
            // Mark all merged indices as processed
            processedIndices.formUnion(mergedIndices)
            mergedDetections.append(mergedDetection)
        }
        
        return mergedDetections
    }
    
    private func boundingBoxesOverlap(_ box1: CGRect, _ box2: CGRect) -> Bool {
        let intersection = box1.intersection(box2)
        let intersectionArea = intersection.width * intersection.height
        let box1Area = box1.width * box1.height
        let box2Area = box2.width * box2.height
        
        // Consider overlapping if intersection is more than 30% of either box
        let overlapRatio1 = intersectionArea / box1Area
        let overlapRatio2 = intersectionArea / box2Area
        
        return overlapRatio1 > 0.3 || overlapRatio2 > 0.3
    }
}

// MARK: - Async/Await Support
@available(iOS 13.0, *)
extension CVDentitionService {
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

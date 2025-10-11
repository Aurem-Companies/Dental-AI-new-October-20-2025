import Foundation
import CoreGraphics

// MARK: - Detection Factory
class DetectionFactory {
    
    // MARK: - Factory Methods
    static func make() -> DetectionService {
        return make(useMLDetection: FeatureFlags.useMLDetection)
    }
    
    static func make(useMLDetection: Bool) -> DetectionService {
        if useMLDetection {
            return makeMLDetectionService()
        } else {
            return makeCVDetectionService()
        }
    }
    
    // MARK: - Service Creation
    private static func makeMLDetectionService() -> DetectionService {
        // Use ONNX service instead of CoreML service
        return makeONNXDetectionService()
    }
    
    private static func makeONNXDetectionService() -> DetectionService {
        return ONNXDetectionService()
    }
    
    private static func makeCVDetectionService() -> DetectionService {
        return CVDentitionService()
    }
    
    // MARK: - Service with Fallback
    static func makeWithFallback() -> DetectionService {
        let primaryService = makeMLDetectionService()
        
        // If primary service fails, return fallback service
        if let mlService = primaryService as? MLDetectionService, !mlService.isModelAvailable {
            return makeCVDetectionService()
        }
        
        return primaryService
    }
    
    // MARK: - Service Validation
    static func validateService(_ service: DetectionService) -> Bool {
        switch service {
        case is MLDetectionService:
            return (service as! MLDetectionService).isModelAvailable
        case is CVDentitionService:
            return true // CV service is always available
        default:
            return false
        }
    }
    
    // MARK: - Service Information
    static func getServiceInfo(_ service: DetectionService) -> String {
        switch service {
        case is MLDetectionService:
            let mlService = service as! MLDetectionService
            return "ML Detection Service - \(mlService.modelStatus)"
        case is CVDentitionService:
            return "CV Detection Service - Available"
        default:
            return "Unknown Service"
        }
    }
    
    // MARK: - Service Comparison
    static func compareServices() -> String {
        let mlService = MLDetectionService()
        let cvService = CVDentitionService()
        
        var comparison = "Service Comparison:\n"
        comparison += "• ML Service: \(mlService.isModelAvailable ? "Available" : "Not Available")\n"
        comparison += "• CV Service: Available\n"
        comparison += "• Current Selection: \(FeatureFlags.useMLDetection ? "ML" : "CV")\n"
        comparison += "• Fallback Enabled: \(FeatureFlags.enableFallback)"
        
        return comparison
    }
}

// MARK: - Service Testing
extension DetectionFactory {
    
    // MARK: - Test Detection
    static func testDetection(service: DetectionService, image: CGImage) -> Result<[Detection], Error> {
        do {
            let detections = try service.detect(in: image)
            return .success(detections)
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Test All Services
    static func testAllServices(image: CGImage) -> [String: Result<[Detection], Error>] {
        var results: [String: Result<[Detection], Error>] = [:]
        
        // Test ML Service
        let mlService = MLDetectionService()
        results["ML"] = testDetection(service: mlService, image: image)
        
        // Test CV Service
        let cvService = CVDentitionService()
        results["CV"] = testDetection(service: cvService, image: image)
        
        return results
    }
    
    // MARK: - Performance Test
    static func performanceTest(service: DetectionService, image: CGImage, iterations: Int = 10) -> TimeInterval {
        let startTime = Date()
        
        for _ in 0..<iterations {
            do {
                _ = try service.detect(in: image)
            } catch {
                // Ignore errors for performance testing
            }
        }
        
        let endTime = Date()
        return endTime.timeIntervalSince(startTime) / Double(iterations)
    }
}

// MARK: - Service Configuration
extension DetectionFactory {
    
    // MARK: - Configure Service
    static func configureService(_ service: DetectionService) {
        // Apply feature flag settings to service
        if let mlService = service as? MLDetectionService {
            // ML-specific configuration could go here
            print("Configuring ML Detection Service")
        } else if let cvService = service as? CVDentitionService {
            // CV-specific configuration could go here
            print("Configuring CV Detection Service")
        }
    }
    
    // MARK: - Service Capabilities
    static func getServiceCapabilities(_ service: DetectionService) -> [String] {
        switch service {
        case is MLDetectionService:
            return [
                "High accuracy detection",
                "Trained on dental images",
                "Real-time inference",
                "Confidence scoring"
            ]
        case is CVDentitionService:
            return [
                "Computer vision detection",
                "No model required",
                "Fast processing",
                "Fallback option"
            ]
        default:
            return []
        }
    }
}

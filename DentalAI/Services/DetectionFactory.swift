import Foundation
import CoreGraphics

// MARK: - Detection Factory
class DetectionFactory {
    
    // MARK: - Factory Methods
    static func make() -> DetectionService {
        return makeWithFallback()
    }
    
    static func makeWithFeatureFlags() -> DetectionService {
        if FeatureFlags.useMLDetection {
            return makeMLDetectionService()
        } else if FeatureFlags.useONNXDetection {
            return makeONNXDetectionService()
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
    static func makeWithFallback(flags: FeatureFlags = .current) -> DetectionService {
        // Priority: ONNX -> ML -> CV (as you verified previously)
        if flags.useONNXDetection {
            #if canImport(ONNXRuntime) || canImport(OrtMobile)
            let onnx = ONNXDetectionService()
            if onnx.isModelAvailable {
                return onnx
            }
            #endif
            // No ONNX libs or not available -> fall through
        }

        if flags.useMLDetection {
            let ml = MLDetectionService()
            if ml.isModelAvailable {
                return ml
            }
        }

        // Fallback to CV always available path
        return CVDentitionService()
    }
    
    // MARK: - Service Validation
    static func validateService(_ service: DetectionService) -> Bool {
        switch service {
        case is MLDetectionService:
            return (service as! MLDetectionService).isModelAvailable
        case is CVDentitionService:
            return true // CV service is always available
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        case is ONNXDetectionService:
            return true // ONNX service is always available
        #endif
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
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        case is ONNXDetectionService:
            return "ONNX Detection Service - Available"
        #endif
        default:
            return "Unknown Service"
        }
    }
    
    // MARK: - Service Comparison
    static func compareServices() -> String {
        let mlService = MLDetectionService()
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        let onnxService = ONNXDetectionService()
        #endif
        let _ = CVDentitionService()
        
        var comparison = "Service Comparison:\n"
        comparison += "• ML Service: \(mlService.isModelAvailable ? "Available" : "Not Available")\n"
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        comparison += "• ONNX Service: Available\n"
        #endif
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
        
        // Test ONNX Service
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        let onnxService = ONNXDetectionService()
        results["ONNX"] = testDetection(service: onnxService, image: image)
        #endif
        
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
        if service is MLDetectionService {
            // ML-specific configuration could go here
            print("Configuring ML Detection Service")
        } else if service is CVDentitionService {
            // CV-specific configuration could go here
            print("Configuring CV Detection Service")
        }
        
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        if service is ONNXDetectionService {
            // ONNX-specific configuration could go here
            print("Configuring ONNX Detection Service")
        }
        #endif
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
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        case is ONNXDetectionService:
            return [
                "ONNX model inference",
                "Cross-platform compatibility",
                "Fast processing",
                "Confidence scoring"
            ]
        #endif
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

// MARK: - Model Loading Helper
enum ModelLoadError: Error {
    case modelNotFound(String)
    case invalidModel
    case loadingFailed(String)
}

func modelURL(named name: String, ext: String) throws -> URL {
    guard let modelURL = Bundle.main.url(forResource: name, withExtension: ext) else {
        throw ModelLoadError.modelNotFound("\(name).\(ext)")
    }
    return modelURL
}

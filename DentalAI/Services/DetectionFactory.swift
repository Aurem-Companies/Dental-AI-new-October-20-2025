import Foundation
import os

// Helper protocols to support both availability shapes across services.
private protocol _HasAvailabilityVar { var isModelAvailable: Bool { get } }
private protocol _HasAvailabilityFunc { func isModelAvailable() -> Bool }

// Adapter that returns a Bool regardless of whether a service exposes
// availability as a var or a method. Defaults to true if neither is present.
private func _isAvailable(_ service: Any) -> Bool {
    if let s = service as? _HasAvailabilityVar { return s.isModelAvailable }
    if let s = service as? _HasAvailabilityFunc { return s.isModelAvailable() }
    return true
}

enum DetectionFactory {
    private static let log = Logger(subsystem: "com.yourorg.DentalAI", category: "DetectionFactory")

    static func makeWithFallback() -> DetectionService {
        let f = FeatureFlags.current
        RuntimeChecks.validateFlags(f)

        // 1) ONNX
        if f.useONNXDetection {
            let onnx = ONNXDetectionService()
            if _isAvailable(onnx) {
                log.debug("Using ONNXDetectionService")
                return onnx
            } else {
                log.error("ONNX requested but unavailable — will try ML/CV.")
            }
        }

        // 2) ML
        if f.useMLDetection {
            let ml = MLDetectionService()
            if _isAvailable(ml) {
                log.debug("Using MLDetectionService")
                return ml
            } else {
                log.error("ML requested but unavailable — will try CV.")
            }
        }

        // 3) CV (guaranteed safety net)
        if f.useCVDetection {
            log.debug("Using CVDentitionService (fallback)")
            return CVDentitionService()
        }

        // Absolute last resort: never return a nil/invalid service
        log.fault("All detection paths disabled; forcing CVDentitionService to prevent app breakage.")
        return CVDentitionService()
    }

    static func make(preferred: [DetectionBackend]) -> DetectionService {
        let f = FeatureFlags.current
        RuntimeChecks.validateFlags(f)

        for backend in preferred {
            switch backend {
            case .onnx where f.useONNXDetection:
                let svc = ONNXDetectionService()
                if _isAvailable(svc) { return svc }
            case .ml where f.useMLDetection:
                let svc = MLDetectionService()
                if _isAvailable(svc) { return svc }
            case .cv where f.useCVDetection:
                return CVDentitionService()
            default:
                continue
            }
        }
        return CVDentitionService()
    }
}

enum DetectionBackend { case onnx, ml, cv }
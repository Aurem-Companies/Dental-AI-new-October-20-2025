import Foundation
import os

protocol DetectionService {
    func detect(in pixelBuffer: CVPixelBuffer) -> [DetectionResult]
    var isModelAvailable: Bool { get }
}

enum DetectionFactory {
    private static let log = Logger(subsystem: "com.yourorg.DentalAI", category: "DetectionFactory")

    static func makeWithFallback() -> DetectionService {
        // ✅ Use instance, not type members
        let f = FeatureFlags.current
        RuntimeChecks.validateFlags(f)

        // === Priority: ONNX → ML → CV ===
        if f.useONNXDetection {
            let onnx = ONNXDetectionService()
            if onnx.isModelAvailable {
                log.debug("Using ONNXDetectionService")
                return onnx
            } else {
                log.error("ONNX requested but unavailable — will try ML/CV.")
            }
        }

        if f.useMLDetection {
            let ml = MLDetectionService()
            if ml.isModelAvailable {
                log.debug("Using MLDetectionService")
                return ml
            } else {
                log.error("ML requested but unavailable — will try CV.")
            }
        }

        if f.useCVDetection {
            log.debug("Using CVDentitionService (fallback)")
            return CVDentitionService()
        }

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
                if svc.isModelAvailable { return svc }
            case .ml where f.useMLDetection:
                let svc = MLDetectionService()
                if svc.isModelAvailable { return svc }
            case .cv where f.useCVDetection:
                let svc = CVDentitionService()
                return svc
            default:
                continue
            }
        }
        return CVDentitionService()
    }
}

enum DetectionBackend { case onnx, ml, cv }
import Foundation

enum FeatureFlagsSummary {
    static func text(for f: FeatureFlags) -> String {
        let onnx = f.useONNXDetection ? "ONNX" : "-"
        let ml   = f.useMLDetection   ? "ML"   : "-"
        let cv   = f.useCVDetection   ? "CV"   : "-"
        let fb   = f.enableFallback   ? "✓"    : "✗"
        let hp   = f.highPerformanceMode ? "✓" : "✗"
        let thr  = String(format: "%.2f", f.modelConfidenceThreshold)
        return "Flags → [\(onnx) \(ml) \(cv)] fallback:\(fb) HP:\(hp) thr:\(thr)"
    }
}

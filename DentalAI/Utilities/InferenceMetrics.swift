import Foundation
import os

final class InferenceMetrics {
    static let shared = InferenceMetrics()
    private let log = Logger(subsystem: "com.yourorg.DentalAI", category: "Inference")
    private let q = DispatchQueue(label: "InferenceMetrics.q")

    private(set) var count: Int = 0
    private(set) var p50LatencyMs: Double = 0
    private(set) var p95LatencyMs: Double = 0
    private var latencies: [Double] = []
    private var confidences: [Double] = []

    func record(latencyMs: Double, confidence: Double) {
        q.async {
            self.count += 1
            self.latencies.append(latencyMs)
            self.confidences.append(confidence)
            if self.latencies.count % 20 == 0 { self.recompute() }
        }
    }

    private func recompute() {
        let ls = latencies.sorted()
        func pct(_ p: Double) -> Double {
            guard !ls.isEmpty else { return 0 }
            let idx = Int((p * Double(ls.count - 1)).rounded())
            return ls[max(0, min(idx, ls.count - 1))]
        }
        p50LatencyMs = pct(0.50)
        p95LatencyMs = pct(0.95)
        log.debug("N=\(self.count, privacy: .public) p50=\(self.p50LatencyMs, privacy: .public)ms p95=\(self.p95LatencyMs, privacy: .public)ms")
    }

    #if DEBUG
    func dumpSnapshot() -> String {
        q.sync {
            let avgConf = confidences.isEmpty ? 0 : confidences.reduce(0,+)/Double(confidences.count)
            return "Inference: N=\(count) p50=\(Int(p50LatencyMs))ms p95=\(Int(p95LatencyMs))ms avgConf=\(String(format: "%.2f", avgConf))"
        }
    }
    #endif
}

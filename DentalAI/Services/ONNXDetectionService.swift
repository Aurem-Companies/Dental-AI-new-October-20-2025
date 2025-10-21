import Foundation
import CoreGraphics

#if DEBUG
/// DEBUG-only: Leave false to keep behavior identical. Flip true after clean build to test YOLO postproc.
private let DEBUG_ENABLE_YOLO_POSTPROC = false
#endif

// Do NOT wrap the type declaration in #if. The class must always exist so callers compile.
final class ONNXDetectionService: DetectionService {

    // MARK: - Init
    init() {}

    // MARK: - Availability
    /// Returns true when an ONNX model is bundle-present AND the runtime is linkable.
    func isModelAvailable() -> Bool {
        // Prefer this simple check to keep callers honest:
        // 1) Model file present?
        let hasModel = ModelLocator.modelExists(name: "dental_model", ext: "onnx") // adjust name if needed

        // 2) Runtime actually importable?
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        let hasRuntime = true
        #else
        let hasRuntime = false
        #endif

        return hasModel && hasRuntime
    }

    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        // If runtime isn't present, be a safe no-op.
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        
        // TODO: Wire real ORT session + inference here.
        // For now, simulate YOLO outputs for testing post-processing
        
        // Simulate raw YOLO tensor outputs (this would come from ONNX runtime)
        let detCount = 10  // Simulate 10 detections
        let featPerDet = 8  // cx, cy, w, h, obj, class1, class2, class3
        var rawArray: [Float] = []
        rawArray.reserveCapacity(detCount * featPerDet)
        
        // Generate some mock YOLO outputs for testing
        for i in 0..<detCount {
            let cx = Float.random(in: 0.2...0.8)
            let cy = Float.random(in: 0.2...0.8)
            let w = Float.random(in: 0.1...0.3)
            let h = Float.random(in: 0.1...0.3)
            let obj = Float.random(in: -2...2)  // logit before sigmoid
            let cls1 = Float.random(in: -2...2)  // class logits
            let cls2 = Float.random(in: -2...2)
            let cls3 = Float.random(in: -2...2)
            
            rawArray.append(contentsOf: [cx, cy, w, h, obj, cls1, cls2, cls3])
        }
        
        #if DEBUG
        if DEBUG_ENABLE_YOLO_POSTPROC {
            // Build YOLO candidates from raw tensors
            var cands: [YOLOCandidate] = []
            cands.reserveCapacity(detCount)
            for i in 0..<detCount {
                let base = i * featPerDet
                if base + 5 >= rawArray.count { break }
                let cx  = rawArray[base + 0]
                let cy  = rawArray[base + 1]
                let w   = rawArray[base + 2]
                let h   = rawArray[base + 3]
                let obj = YOLOPost.sig(rawArray[base + 4])

                // Remaining are class logits → sigmoid
                let clsStart = base + 5
                let clsEnd = min(base + featPerDet, rawArray.count)
                var scores: [Float] = []
                scores.reserveCapacity(max(0, clsEnd - clsStart))
                var j = clsStart
                while j < clsEnd {
                    scores.append(YOLOPost.sig(rawArray[j]))
                    j += 1
                }
                cands.append(YOLOCandidate(cx: cx, cy: cy, w: w, h: h, obj: obj, scores: scores))
            }

            let params = DetectionParams(minConfidence: Float(FeatureFlags.current.modelConfidenceThreshold),
                                         nmsIoU: 0.45, maxDetections: 100)
            let kept = YOLOPost.postprocess(cands: cands, params: params)

            // Map to Detection format
            let processed: [Detection] = kept.map { cand in
                let rect = YOLOPost.toCGRect(cx: cand.cx, cy: cand.cy, w: cand.w, h: cand.h)
                let label = "cls_\(cand.classIndex)"
                return Detection(label: label, confidence: Double(cand.conf), rect: rect)
            }

            return processed
        }
        #endif

        // Fallback to existing behavior (unchanged)
        return []
        
        #else
        return []
        #endif
    }
}
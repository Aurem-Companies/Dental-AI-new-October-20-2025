import Foundation
import CoreGraphics
import CoreVideo
import UIKit

#if canImport(ONNXRuntime)
import ONNXRuntime
#elseif canImport(OrtMobile)
import OrtMobile
#endif

#if DEBUG
/// DEBUG-only: Leave false to keep behavior identical. Flip true after clean build to test YOLO postproc.
private let DEBUG_ENABLE_YOLO_POSTPROC = false
#endif

// Do NOT wrap the type declaration in #if. The class must always exist so callers compile.
final class ONNXDetectionService: DetectionService {
    
    // MARK: - Properties
    #if canImport(ONNXRuntime) || canImport(OrtMobile)
    private var session: Any? // Will be ORTSession or similar
    private let inputName = "images"
    private let outputName = "output0"
    #endif

    // MARK: - Init
    init() {
        #if canImport(ONNXRuntime) || canImport(OrtMobile)
        // TODO: Initialize ONNX session here
        // Example with ORT:
        // do {
        //     let modelURL = Bundle.main.url(forResource: "dental_model", withExtension: "onnx")!
        //     session = try ORTSession(env: ORTEnv(), modelPath: modelURL.path)
        // } catch {
        //     print("Failed to initialize ONNX session: \(error)")
        //     session = nil
        // }
        
        // For now, simulate session availability for testing
        session = "mock_session" // Placeholder - replace with real ORTSession
        #endif
    }

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
        
        // Check if session is available
        guard session != nil else {
            // Session not initialized - return empty for now
            return []
        }
        
        // TODO: Implement real ONNX inference here
        // Example with ORT:
        // let inputTensor = try ORTValue(tensorData: NSMutableData(data: inputData), 
        //                               elementType: .float, shape: [1, 3, 640, 640])
        // let outputs = try session.run(withInputs: [inputName: inputTensor], 
        //                               outputNames: [outputName])
        // let out = outputs[outputName]!
        // let rawArray: [Float] = out.toArray(Float.self)
        
        // For now, simulate the expected output shape [1, 84, 3549]
        // This will be replaced with actual ONNX runtime calls above
        
        // Simulate real YOLO outputs with correct shape [1, 84, 3549]
        // Shape: [batch=1, features=84, detections=3549]
        let batchSize = 1
        let featureCount = 84  // cx, cy, w, h, obj + 79 class scores
        let detectionCount = 3549
        
        var rawArray: [Float] = []
        rawArray.reserveCapacity(batchSize * featureCount * detectionCount)
        
        // Generate realistic YOLO outputs
        for d in 0..<detectionCount {
            // cx, cy, w, h (normalized coordinates 0-1)
            let cx = Float.random(in: 0.0...1.0)
            let cy = Float.random(in: 0.0...1.0)
            let w = Float.random(in: 0.01...0.3)
            let h = Float.random(in: 0.01...0.3)
            
            // objectness logit (before sigmoid)
            let obj = Float.random(in: -3...3)
            
            // class logits (before sigmoid) - 79 classes
            var classLogits: [Float] = []
            classLogits.reserveCapacity(79)
            for _ in 0..<79 {
                classLogits.append(Float.random(in: -3...3))
            }
            
            // Add to raw array in [D, F] format (detection, feature)
            rawArray.append(cx)
            rawArray.append(cy)
            rawArray.append(w)
            rawArray.append(h)
            rawArray.append(obj)
            rawArray.append(contentsOf: classLogits)
        }
        
        #if DEBUG
        if DEBUG_ENABLE_YOLO_POSTPROC {
            // 1) Run the real ONNX inference (adapt to your runtime API)
            // Example with ORT-style API; replace with your actual calls:
            // let outputs = try session.run(withInputs: [inputName: inputTensor], outputNames: [outputName])
            // let out = outputs[outputName]!
            // let outShape = out.shape // e.g., [1, N, D] or [1, D, N]
            // let rawArray: [Float] = out.toArray(Float.self)

            // --- BEGIN: SHAPE NORMALIZATION ---
            // You reported shape [1, 84, 3549]. We must normalize to [1, N, D] (N=detections, D=features).
            // If your tensor is [1, N, D] already:
            var N = detectionCount  // 3549 detections
            var D = featureCount    // 84 features per detection
            var rawArrayND: [Float] = rawArray

            // If your tensor is [1, D, N], transpose it into [1, N, D].
            // Our simulated data is already in [D, N] format, so we need to transpose to [N, D]
            if true { // Always transpose since we're simulating [1, 84, 3549] → [1, 3549, 84]
                // Transpose from [D, N] to [N, D]
                let oldN = detectionCount, oldD = featureCount
                var transposed = [Float](repeating: 0, count: oldN * oldD)
                for d in 0..<oldD {
                    for n in 0..<oldN {
                        transposed[n * oldD + d] = rawArray[d * oldN + n]
                    }
                }
                rawArrayND = transposed
                N = oldN  // 3549
                D = oldD  // 84
            }
            // --- END: SHAPE NORMALIZATION ---

            // 2) Build YOLO candidates (expects per det: [cx,cy,w,h,obj, classLogits...])
            // If your model outputs normalized coords (0..1), you can scale later to image size.
            var cands: [YOLOCandidate] = []
            cands.reserveCapacity(N)
            for i in 0..<N {
                let base = i * D
                if base + 5 > rawArrayND.count { break }

                let cx  = rawArrayND[base + 0]
                let cy  = rawArrayND[base + 1]
                let w   = rawArrayND[base + 2]
                let h   = rawArrayND[base + 3]
                let obj = YOLOPost.sig(rawArrayND[base + 4])

                var scores: [Float] = []
                scores.reserveCapacity(max(0, D - 5))
                var j = base + 5
                while j < base + D {
                    scores.append(YOLOPost.sig(rawArrayND[j]))
                    j += 1
                }
                cands.append(YOLOCandidate(cx: cx, cy: cy, w: w, h: h, obj: obj, scores: scores))
            }

            // 3) Post-process with thresholds (confidence from FeatureFlags)
            let params = DetectionParams(
                minConfidence: Float(FeatureFlags.current.modelConfidenceThreshold),
                nmsIoU: 0.45,
                maxDetections: 100
            )
            let kept = YOLOPost.postprocess(cands: cands, params: params)

            // 4) Map to Detection format with proper coordinate scaling
            // Scale normalized coordinates (0-1) to image pixel dimensions
            let imageWidth = Float(image.width)
            let imageHeight = Float(image.height)
            
            let processed: [Detection] = kept.map { cand in
                // Scale normalized coordinates to image dimensions
                let scaledCx = cand.cx * imageWidth
                let scaledCy = cand.cy * imageHeight
                let scaledW = cand.w * imageWidth
                let scaledH = cand.h * imageHeight
                
                let rect = YOLOPost.toCGRect(cx: scaledCx, cy: scaledCy, w: scaledW, h: scaledH)
                let label = DentalLabels.label(for: cand.classIndex)
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
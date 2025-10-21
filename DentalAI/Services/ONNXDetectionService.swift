import Foundation
import CoreGraphics
import CoreVideo
import UIKit
import ONNXRuntime

#if DEBUG
/// DEBUG-only: Leave false to keep behavior identical. Flip true after clean build to test YOLO postproc.
private let DEBUG_ENABLE_YOLO_POSTPROC = false
#endif

// Do NOT wrap the type declaration in #if. The class must always exist so callers compile.
final class ONNXDetectionService: DetectionService {
    
    // MARK: - Properties
    private let env = try? ORTEnv(loggingLevel: ORTLoggingLevel.warning)
    private var session: ORTSession?
    private let inputName = "images"
    private let outputName = "output0"

    // MARK: - Init
    init() {
        // Initialize ONNX session once
        if let env = env,
           let url = Bundle.main.url(forResource: "dental_model", withExtension: "onnx") {
            do {
                session = try ORTSession(env: env, modelPath: url.path)
            } catch {
                print("❌ ONNX session init failed: \(error)")
                session = nil
            }
        } else {
            print("❌ ONNX env or model URL missing")
            session = nil
        }
    }

    // MARK: - Availability
    /// Returns true when an ONNX model is bundle-present AND the runtime is linkable.
    func isModelAvailable() -> Bool {
        // 1) Model file present?
        let hasModel = ModelLocator.modelExists(name: "dental_model", ext: "onnx")
        
        // 2) Session initialized successfully?
        let hasSession = session != nil
        
        return hasModel && hasSession
    }
    
    // MARK: - Detection
    func detect(in image: CGImage) throws -> [Detection] {
        // Convert CGImage → UIImage for preprocessing
        let img = UIImage(cgImage: image)

        // Preprocess
        guard let (inputData, shape) = ImagePreprocessor.makeNCHWInput(from: img, size: 640) else {
            return []
        }

        guard let session = session else {
            // Session not ready: safe fallback
            return []
        }

        do {
            // Create tensor
            let inputTensor = try ORTValue(tensorData: NSMutableData(data: inputData),
                                           elementType: ORTTensorElementDataType.float,
                                           shape: shape)

            // Run
            let outputs = try session.run(
                withInputs: [inputName: inputTensor],
                outputNames: [outputName],
                runOptions: nil
            )

            guard let out = outputs[outputName] else { return [] }

            // Extract raw floats and shape (e.g., [1, 84, 3549])
            let raw: [Float] = try out.tensorData().toArray(type: Float.self)
            let outShape = try out.tensorData().shape() as? [NSNumber] ?? [1, 84, 3549]

            // Normalize shape to [1, N, D]
            var N = Int(truncating: outShape.count > 2 ? outShape[2] : 0) // detections
            var D = Int(truncating: outShape.count > 1 ? outShape[1] : 0) // features per detection (84)

            var rawND = raw
            // If shape is [1, D, N], transpose to [N, D]
            if outShape.count == 3, D > N {
                let oldN = N, oldD = D
                var transposed = [Float](repeating: 0, count: oldN * oldD)
                for d in 0..<oldD {
                    for n in 0..<oldN {
                        transposed[n * oldD + d] = raw[d * oldN + n]
                    }
                }
                rawND = transposed
                N = oldN
                D = oldD
            } else if outShape.count == 3, N == 0 || D == 0 {
                // Fallback if shape parsing fails; assume known values
                N = 3549; D = 84
            }

            // DEBUG-only post-processing path (opt-in)
            #if DEBUG
            if DEBUG_ENABLE_YOLO_POSTPROC {
                var cands: [YOLOCandidate] = []
                cands.reserveCapacity(N)
                for i in 0..<N {
                    let base = i * D
                    if base + 5 > rawND.count { break }

                    // Model outputs cx,cy,w,h normalized 0..1 (your analysis confirmed)
                    let cx  = rawND[base + 0]
                    let cy  = rawND[base + 1]
                    let w   = rawND[base + 2]
                    let h   = rawND[base + 3]
                    let obj = YOLOPost.sig(rawND[base + 4])

                    var scores: [Float] = []
                    scores.reserveCapacity(max(0, D - 5))
                    var j = base + 5
                    while j < base + D {
                        scores.append(YOLOPost.sig(rawND[j]))
                        j += 1
                    }
                    cands.append(YOLOCandidate(cx: cx, cy: cy, w: w, h: h, obj: obj, scores: scores))
                }

                // Thresholds (minConfidence from FeatureFlags)
                let params = DetectionParams(
                    minConfidence: Float(FeatureFlags.current.modelConfidenceThreshold),
                    nmsIoU: 0.45,
                    maxDetections: 100
                )

                // Post-process
                let kept = YOLOPost.postprocess(cands: cands, params: params)

                // Scale normalized coords to image pixels
                let iw = Float(image.width)
                let ih = Float(image.height)
                let results: [Detection] = kept.map { cand in
                    let rect = YOLOPost.toCGRect(
                        cx: cand.cx * iw, cy: cand.cy * ih,
                        w:  cand.w * iw,  h:  cand.h * ih
                    )
                    let name = DentalLabels.label(for: cand.classIndex)
                    return Detection(label: name,
                                     confidence: Float(cand.conf),
                                     boundingBox: rect)
                }
                return results
            }
            #endif

            // If DEBUG toggle is OFF, you can either:
            // (a) Return an empty array (keeps prod behavior unchanged), or
            // (b) Return a basic parse of rawND without NMS (simple fallback).
            return []
        } catch {
            print("❌ ONNX inference error: \(error)")
            return []
        }
    }
}
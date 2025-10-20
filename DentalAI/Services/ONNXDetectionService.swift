import Foundation
import CoreGraphics

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
        // For now, return empty to keep build green until model pipeline is connected.
        return []
        #else
        return []
        #endif
    }
}
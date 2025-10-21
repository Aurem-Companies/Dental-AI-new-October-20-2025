import Foundation

/// Tunable thresholds for detection filtering & NMS.
/// NOTE: This file is additive; does NOT change behavior until used.
struct DetectionParams {
    /// Minimum score for (objectness * classScore) to keep a candidate
    var minConfidence: Float = 0.25
    /// IoU threshold for Non-Max Suppression
    var nmsIoU: Float = 0.45
    /// Max number of final detections
    var maxDetections: Int = 100
}

import Foundation

enum BackendStatus {
    static var lastUsed: String = "unknown"   // "onnx" | "ml" | "cv" | "unknown"
    static var modelStyle: String = "unknown" // "yolo" | "generic" | "unknown"
}

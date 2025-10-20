import Foundation

// Provide the method expected by DetectionViewModel.
// Forward to the real persistence clear implementation.
extension DataManager {

    /// Backward-compat API expected by DetectionViewModel.
    /// Forwards to the real clearAllAnalysisHistory() implementation.
    func clearAnalysisHistory() {
        // Forward to the real implementation that clears UserDefaults and file system
        self.clearAllAnalysisHistory()
    }
}

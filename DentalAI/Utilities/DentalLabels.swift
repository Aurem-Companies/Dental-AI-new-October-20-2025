import Foundation

/// Helper to load dental class labels from Labels.plist
enum DentalLabels {
    private static var _labels: [String]?
    
    static var labels: [String] {
        if let cached = _labels {
            return cached
        }
        
        guard let url = Bundle.main.url(forResource: "Labels", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String] else {
            // Fallback to generic labels if plist fails to load
            _labels = (0..<79).map { "class_\($0)" }
            return _labels!
        }
        
        _labels = plist
        return plist
    }
    
    static func label(for classIndex: Int) -> String {
        let labels = self.labels
        guard classIndex >= 0 && classIndex < labels.count else {
            return "unknown_\(classIndex)"
        }
        return labels[classIndex]
    }
}

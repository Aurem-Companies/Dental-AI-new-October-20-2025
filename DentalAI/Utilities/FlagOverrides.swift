import Foundation

enum FlagOverrides {
    #if DEBUG
    static func apply(to flags: inout FeatureFlags) {
        let args = ProcessInfo.processInfo.arguments
        let env  = ProcessInfo.processInfo.environment

        func bool(_ key: String, default def: Bool) -> Bool {
            if let v = UserDefaults.standard.object(forKey: key) as? Bool { return v }
            if args.contains("--\(key)") { return true }
            if let s = env[key]?.lowercased() { return ["1","true","yes"].contains(s) }
            return def
        }

        func double(_ key: String, default def: Double) -> Double {
            if let v = UserDefaults.standard.object(forKey: key) as? Double { return v }
            if let s = env[key], let v = Double(s) { return v }
            if let i = args.firstIndex(of: "--\(key)"), args.indices.contains(args.index(after: i)) {
                return Double(args[args.index(after: i)]) ?? def
            }
            return def
        }

        flags.useONNXDetection        = bool("useONNXDetection",        default: flags.useONNXDetection)
        flags.useMLDetection          = bool("useMLDetection",          default: flags.useMLDetection)
        flags.useCVDetection          = bool("useCVDetection",          default: flags.useCVDetection)
        flags.enableFallback          = bool("enableFallback",          default: flags.enableFallback)
        flags.debugMode               = bool("debugMode",               default: flags.debugMode)
        flags.highPerformanceMode     = bool("highPerformanceMode",     default: flags.highPerformanceMode)
        flags.modelConfidenceThreshold = double("modelConfidenceThreshold",
                                                default: flags.modelConfidenceThreshold)
    }
    #else
    static func apply(to flags: inout FeatureFlags) {}
    #endif
}

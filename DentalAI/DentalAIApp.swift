import SwiftUI

@main
struct DentalAIApp: App {
    
    init() {
        // Configure feature flags and defaults
        FeatureFlags.configureDefaults()
        FeatureFlags.configureForEnvironment()
        
        print("🚀 DentalAI App Initialized")
        print("📊 \(FeatureFlags.featureStatus)")
        
        // Log model availability on first launch
        let mlService = MLDetectionService()
        print("🔬 ML Model Available: \(mlService.isModelAvailable)")
        print("📋 ML Model Status: \(mlService.modelStatus)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

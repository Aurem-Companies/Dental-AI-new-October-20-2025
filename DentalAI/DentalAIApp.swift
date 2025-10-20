import SwiftUI

@main
struct DentalAIApp: App {
    
    init() {
        // Configure feature flags and defaults
        FeatureFlags.configureDefaults()
        FeatureFlags.configureForEnvironment()
        
        print("🚀 DentalAI App Initialized")
        print("📊 \(FeatureFlags.featureStatus)")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

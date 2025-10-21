import SwiftUI
import os

@main
struct DentalAIApp: App {
    #if DEBUG
    @State private var showMLMisconfigBanner = false
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView() // <-- keep your actual root view here
                .onAppear {
                    // Pull effective flags (truth-based) and validate vs reality
                    let f = FeatureFlags.current
                    RuntimeChecks.validateFlags(f)

                    // Optional: log a concise feature status snapshot
                    let log = Logger(subsystem: "com.yourorg.DentalAI", category: "App")
                    log.debug("\(FeatureFlagsSummary.text(for: f))")

                    #if DEBUG
                    // Show banner if ML is enabled but .mlmodelc is missing
                    if f.useMLDetection && !ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc") {
                        showMLMisconfigBanner = true
                    }
                    #endif
                }
                #if DEBUG
                .overlay(alignment: .top) {
                    if showMLMisconfigBanner {
                        Text("⚠️ ML enabled but DentalModel.mlmodelc not bundled — falling back to CV")
                            .font(.footnote)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.yellow.opacity(0.2))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .transition(.opacity)
                    }
                }
                #endif
        }
    }
}
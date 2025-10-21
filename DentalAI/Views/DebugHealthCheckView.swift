import SwiftUI

#if DEBUG
struct DebugHealthCheckView: View {
    @State private var flags = FeatureFlags.current
    var body: some View {
        List {
            Section(header: Text("Models")) {
                Label("ONNX bundled: \(ModelLocator.modelExists(name: "dental_model", ext: "onnx") ? "Yes" : "No")", systemImage: "cube.box")
                Label("ML .mlmodelc: \(ModelLocator.modelExists(name: "DentalModel", ext: "mlmodelc") ? "Yes" : "No")", systemImage: "square.stack.3d.up")
            }
            Section(header: Text("Flags (effective)")) {
                Text("useONNXDetection: \(flags.useONNXDetection.description)")
                Text("useMLDetection: \(flags.useMLDetection.description)")
                Text("useCVDetection: \(flags.useCVDetection.description)")
                Text("enableFallback: \(flags.enableFallback.description)")
                Text("highPerformanceMode: \(flags.highPerformanceMode.description)")
                Text("modelConfidenceThreshold: \(flags.modelConfidenceThreshold)")
            }
            Section(header: Text("Inference")) {
                Text(InferenceMetrics.shared.dumpSnapshot())
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Health Check")
        .onAppear { flags = FeatureFlags.current; RuntimeChecks.validateFlags(flags) }
    }
}
#endif

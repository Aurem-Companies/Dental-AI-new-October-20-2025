import SwiftUI
import UIKit
import AVFoundation

// MARK: - Camera View
struct CameraView: UIViewControllerRepresentable {
    @ObservedObject var detectionViewModel: DetectionViewModel
    @Binding var showingImageAnalysis: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        
        // Check if camera is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ Camera not available")
            return picker
        }
        
        // Configure camera with fallback options
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.cameraDevice = .rear
        } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }
        
        // Configure flash mode with fallback
        if UIImagePickerController.isFlashAvailable(for: picker.cameraDevice) {
            picker.cameraFlashMode = .auto
        } else {
            picker.cameraFlashMode = .off
        }
        
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        picker.showsCameraControls = true
        
        print("✅ Camera configured - Device: \(picker.cameraDevice == .rear ? "rear" : "front")")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    var body: some View {
        EmptyView()
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                print("✅ Image captured successfully - Size: \(image.size)")
                parent.processImage(image)
            } else {
                print("❌ Failed to capture image")
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📷 Camera cancelled by user")
            parent.dismiss()
        }
    }
    
    private func processImage(_ image: UIImage) {
        print("🔄 Photo captured - showing analysis screen immediately")
        print("🔄 Image size: \(image.size)")
        
        // Show analysis screen immediately
        DispatchQueue.main.async {
            self.showingImageAnalysis = true
            print("🔄 Analysis screen shown immediately")
        }
        
        // Start analysis in background
        Task {
            do {
                let result = try await detectionViewModel.analyzeImage(image)
                await MainActor.run {
                    print("✅ Analysis completed successfully")
                    print("📊 Result: \(result.healthScore) health score")
                    print("🔍 Conditions detected: \(result.detectedConditions.count)")
                }
            } catch {
                await MainActor.run {
                    print("❌ Analysis failed: \(error)")
                }
            }
        }
    }
}


// MARK: - Image Capture View
struct ImageCaptureView: View {
    @ObservedObject var detectionViewModel: DetectionViewModel
    @Binding var showingImageAnalysis: Bool
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var analysisError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text("📸 Capture Your Smile")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Take a clear photo of your teeth for analysis")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            
            // Image Preview
            if let image = capturedImage {
                VStack(spacing: 16) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    // Analysis Button
                    Button(action: analyzeImage) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "magnifyingglass")
                            }
                            Text(isAnalyzing ? "Analyzing..." : "Analyze Image")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isAnalyzing)
                }
            } else {
                // Capture Options
                VStack(spacing: 16) {
                    Text("Choose how you'd like to capture your image:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        Button(action: { showingCamera = true }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take Photo")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        
                        Button(action: { showingPhotoLibrary = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choose from Library")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            // Error Message
            if let error = analysisError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingCamera) {
            CameraView(
                detectionViewModel: detectionViewModel,
                showingImageAnalysis: $showingImageAnalysis
            )
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoLibraryView(
                detectionViewModel: detectionViewModel,
                showingImageAnalysis: $showingImageAnalysis
            )
        }
    }
    
    private func analyzeImage() {
        guard let image = capturedImage else { return }
        
        isAnalyzing = true
        analysisError = nil
        
        Task {
            do {
                let _ = try await detectionViewModel.analyzeImage(image)
                await MainActor.run {
                    isAnalyzing = false
                    showingImageAnalysis = true
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    analysisError = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Camera Permission Manager
class CameraPermissionManager: ObservableObject {
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    init() {
        checkPermissionStatus()
    }
    
    func checkPermissionStatus() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.checkPermissionStatus()
            }
        }
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    @ObservedObject var cameraPermissionManager: CameraPermissionManager
    let onPermissionGranted: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("📸 Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("DentalAI needs access to your camera to capture photos of your teeth for analysis.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Grant Permission") {
                cameraPermissionManager.requestPermission()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
        .padding()
        .onChange(of: cameraPermissionManager.permissionStatus) { status in
            if status == .authorized {
                onPermissionGranted()
            }
        }
    }
}

// MARK: - Image Quality Overlay
struct ImageQualityOverlay: View {
    let quality: ImageQuality
    let suggestions: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Image Quality")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(quality.qualityLevel.emoji)
                    .font(.title2)
            }
            
            Text(quality.qualityLevel.displayName)
                .font(.subheadline)
                .foregroundColor(quality.qualityLevel.color)
            
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Suggestions:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

// MARK: - Real-time Validation Overlay
struct RealTimeValidationOverlay: View {
    let validation: RealTimeValidationResult
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Real-time Validation")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if validation.isReadyForAnalysis {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
            
            if validation.isReadyForAnalysis {
                Text("Ready for analysis")
                    .font(.subheadline)
                    .foregroundColor(.green)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Improve image quality:")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    ForEach(validation.suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}

// MARK: - Preview
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        ImageCaptureView(
            detectionViewModel: DetectionViewModel(),
            showingImageAnalysis: .constant(false)
        )
    }
}
import SwiftUI
import UIKit

// MARK: - Photo Library View
struct PhotoLibraryView: UIViewControllerRepresentable {
    @ObservedObject var detectionViewModel: DetectionViewModel
    @Binding var showingImageAnalysis: Bool
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoLibraryView
        
        init(_ parent: PhotoLibraryView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                print("✅ Image selected from library")
                parent.processImage(image)
            } else {
                print("❌ Failed to select image")
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("📷 Photo library cancelled by user")
            parent.dismiss()
        }
    }
    
    private func processImage(_ image: UIImage) {
        print("🔄 Photo selected from library - showing crop view")
        // For now, directly analyze the image (could add crop view here too)
        Task {
            do {
                let result = try await detectionViewModel.analyzeImage(image)
                await MainActor.run {
                    print("✅ Photo library analysis completed successfully")
                    print("📊 Result: \(result.healthScore) health score")
                    print("🔍 Conditions detected: \(result.detectedConditions.count)")
                    showingImageAnalysis = true
                }
            } catch {
                await MainActor.run {
                    print("❌ Photo library analysis failed: \(error)")
                    // Still show the analysis view even if there's an error
                    showingImageAnalysis = true
                }
            }
        }
    }
}

import SwiftUI
import UIKit

// MARK: - Image Crop View
struct ImageCropView: View {
    let originalImage: UIImage
    @Binding var showingImageAnalysis: Bool
    @ObservedObject var detectionViewModel: DetectionViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var cropRect = CGRect(x: 0.2, y: 0.3, width: 0.6, height: 0.4)
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(spacing: 8) {
                    Text("🦷 Focus on Your Smile")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Adjust the crop to focus on your teeth and smile area")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Image with crop overlay
                GeometryReader { geometry in
                    ZStack {
                        // Background image
                        Image(uiImage: originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Crop overlay
                        CropOverlay(
                            cropRect: $cropRect,
                            imageSize: originalImage.size,
                            viewSize: geometry.size
                        )
                    }
                }
                .frame(height: 400)
                .background(Color.black.opacity(0.1))
                .cornerRadius(12)
                
                // Crop controls
                VStack(spacing: 12) {
                    Text("Crop Area")
                        .font(.headline)
                    
                    HStack {
                        Text("Width")
                        Slider(value: Binding(
                            get: { cropRect.width },
                            set: { cropRect.size.width = $0 }
                        ), in: 0.3...0.8)
                        Text("\(Int(cropRect.width * 100))%")
                            .frame(width: 40)
                    }
                    
                    HStack {
                        Text("Height")
                        Slider(value: Binding(
                            get: { cropRect.height },
                            set: { cropRect.size.height = $0 }
                        ), in: 0.2...0.6)
                        Text("\(Int(cropRect.height * 100))%")
                            .frame(width: 40)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                    
                    Button(action: processCroppedImage) {
                        HStack {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Analyze Cropped Image")
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .disabled(isProcessing)
                }
            }
            .padding()
            .navigationTitle("Crop Image")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func processCroppedImage() {
        isProcessing = true
        
        Task {
            do {
                let croppedImage = cropImage(originalImage, to: cropRect)
                let _ = try await detectionViewModel.analyzeImage(croppedImage)
                
                await MainActor.run {
                    isProcessing = false
                    showingImageAnalysis = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    print("❌ Error analyzing cropped image: \(error)")
                    // Still show analysis view with error
                    showingImageAnalysis = true
                    dismiss()
                }
            }
        }
    }
    
    private func cropImage(_ image: UIImage, to rect: CGRect) -> UIImage {
        let cgImage = image.cgImage!
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        let cropRect = CGRect(
            x: rect.origin.x * imageWidth,
            y: rect.origin.y * imageHeight,
            width: rect.width * imageWidth,
            height: rect.height * imageHeight
        )
        
        let croppedCGImage = cgImage.cropping(to: cropRect)!
        return UIImage(cgImage: croppedCGImage)
    }
}

// MARK: - Crop Overlay
struct CropOverlay: View {
    @Binding var cropRect: CGRect
    let imageSize: CGSize
    let viewSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let scale = min(geometry.size.width / imageSize.width, geometry.size.height / imageSize.height)
            let scaledImageSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let offset = CGSize(
                width: (geometry.size.width - scaledImageSize.width) / 2,
                height: (geometry.size.height - scaledImageSize.height) / 2
            )
            
            ZStack {
                // Dark overlay
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: scaledImageSize.width, height: scaledImageSize.height)
                    .offset(offset)
                
                // Crop window
                Rectangle()
                    .fill(Color.clear)
                    .frame(
                        width: cropRect.width * scaledImageSize.width,
                        height: cropRect.height * scaledImageSize.height
                    )
                    .overlay(
                        Rectangle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(
                        x: (cropRect.origin.x - 0.5) * scaledImageSize.width + offset.width,
                        y: (cropRect.origin.y - 0.5) * scaledImageSize.height + offset.height
                    )
            }
        }
    }
}

import SwiftUI
import UIKit

struct PhotoAdjustmentView: View {
    let originalImage: UIImage
    @ObservedObject var detectionViewModel: DetectionViewModel
    @Binding var showingImageAnalysis: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isAnalyzing = false
    
    var body: some View {
        ZStack {
            Color.red.ignoresSafeArea() // Test color to see if view is loading
            
            VStack {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Adjust Photo")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty space to balance the layout
                    Text("")
                        .foregroundColor(.clear)
                }
                .padding()
                
                Spacer()
                
                // Photo with zoom and pan
                GeometryReader { geometry in
                    Image(uiImage: originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { value in
                                        lastScale = scale
                                        // Limit zoom range
                                        if scale < 1.0 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                scale = 1.0
                                                lastScale = 1.0
                                            }
                                        } else if scale > 3.0 {
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                scale = 3.0
                                                lastScale = 3.0
                                            }
                                        }
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                    }
                            )
                        )
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                
                Spacer()
                
                // Instructions and Analyze Button
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Text("Pinch to zoom • Drag to pan")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Focus on your smile area")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: {
                        analyzeAdjustedPhoto()
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Analyze This Area")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .disabled(isAnalyzing)
                }
                .padding(.bottom, 30)
            }
            
            // Loading overlay
            if isAnalyzing {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Analyzing your photo...")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("This may take a few moments")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .onAppear {
            print("🖼️ PhotoAdjustmentView appeared with image size: \(originalImage.size)")
            print("🖼️ PhotoAdjustmentView isAnalyzing: \(isAnalyzing)")
        }
    }
    
    // MARK: - Methods
    private func analyzeAdjustedPhoto() {
        isAnalyzing = true
        
        // Create adjusted image
        let adjustedImage = createAdjustedImage()
        
        Task {
            do {
                let _ = try await detectionViewModel.analyzeImage(adjustedImage)
                await MainActor.run {
                    isAnalyzing = false
                    showingImageAnalysis = true
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    showingImageAnalysis = true
                    dismiss()
                }
            }
        }
    }
    
    private func createAdjustedImage() -> UIImage {
        // For now, return the original image
        // In a more sophisticated implementation, you would create a cropped version
        // based on the current zoom and offset values
        return originalImage
    }
}

#Preview {
    PhotoAdjustmentView(
        originalImage: UIImage(systemName: "photo")!,
        detectionViewModel: DetectionViewModel(),
        showingImageAnalysis: .constant(false)
    )
}
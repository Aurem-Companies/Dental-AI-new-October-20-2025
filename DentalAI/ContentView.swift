import SwiftUI

struct ContentView: View {
    @StateObject private var detectionViewModel = DetectionViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    
    @State private var selectedImage: UIImage?
    @State private var showingImageCapture = false
    @State private var showingAnalysisResults = false
    @State private var userProfile = UserProfile(
        name: "User",
        age: 30,
        dentalHistory: [],
        preferences: UserPreferences()
    )
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Main Content
                        if selectedImage == nil {
                            // Welcome Screen
                            welcomeView
                        } else if detectionViewModel.isAnalyzing {
                            // Analysis Loading
                            analysisLoadingView
                        } else if let result = detectionViewModel.analysisResult {
                            // Analysis Results Summary
                            analysisSummaryView(result)
                        } else {
                            // Image Preview
                            imagePreviewView
                        }
                        
                        // Action Buttons
                        actionButtonsView
                        
                        // Recent History
                        if !userProfile.dentalHistory.isEmpty {
                            recentHistoryView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("DentalAI")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingImageCapture) {
                ImageCaptureView(selectedImage: $selectedImage)
            }
            .sheet(isPresented: $showingAnalysisResults) {
                if let result = detectionViewModel.analysisResult {
                    ImageAnalysisView(analysisResult: result)
                }
            }
            .onChange(of: selectedImage) { image in
                if image != nil {
                    analyzeImage()
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Welcome back, \(userProfile.name)!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Let's check your dental health")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile Button
                Button(action: {}) {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            
            // Health Trend Indicator
            if !userProfile.dentalHistory.isEmpty {
                HStack {
                    Image(systemName: trendIcon)
                        .foregroundColor(trendColor)
                    Text("Health Trend: \(userProfile.healthTrend.rawValue)")
                        .font(.caption)
                        .foregroundColor(trendColor)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(trendColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Welcome View
    private var welcomeView: some View {
        VStack(spacing: 24) {
            // Hero Image
            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Capture Your Smile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Take a photo of your teeth and get instant AI-powered analysis with personalized recommendations for better dental health.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Features
            VStack(spacing: 16) {
                FeatureRow(
                    icon: "brain.head.profile",
                    title: "AI Analysis",
                    description: "Advanced computer vision detects dental conditions"
                )
                
                FeatureRow(
                    icon: "list.bullet.clipboard",
                    title: "Personalized Recommendations",
                    description: "Get tailored advice based on your specific needs"
                )
                
                FeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress Tracking",
                    description: "Monitor your dental health over time"
                )
            }
        }
    }
    
    // MARK: - Analysis Loading View
    private var analysisLoadingView: some View {
        VStack(spacing: 24) {
            // Loading Animation
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("Analyzing Your Photo")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Our AI is examining your teeth for potential issues...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Analysis Steps
            VStack(alignment: .leading, spacing: 12) {
                AnalysisStepView(
                    title: "Image Processing",
                    description: "Enhancing image quality",
                    isCompleted: true
                )
                
                AnalysisStepView(
                    title: "Color Analysis",
                    description: "Analyzing tooth color and health",
                    isCompleted: true
                )
                
                AnalysisStepView(
                    title: "Condition Detection",
                    description: "Identifying dental conditions",
                    isCompleted: false
                )
                
                AnalysisStepView(
                    title: "Recommendations",
                    description: "Generating personalized advice",
                    isCompleted: false
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Image Preview View
    private var imagePreviewView: some View {
        VStack(spacing: 16) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }
            
            Button("Analyze Photo") {
                analyzeImage()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Analysis Summary View
    private func analysisSummaryView(_ result: DentalAnalysisResult) -> some View {
        VStack(spacing: 16) {
            // Health Score Card
            VStack(spacing: 12) {
                Text("Analysis Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack {
                    VStack {
                        Text("\(result.overallHealthScore)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(healthScoreColor(result.overallHealthScore))
                        Text("Health Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("\(Int(result.confidence * 100))%")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("Confidence")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Primary Condition
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Condition")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(conditionColor(result.primaryCondition))
                    
                    Text(result.primaryCondition.rawValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding()
                .background(conditionColor(result.primaryCondition).opacity(0.1))
                .cornerRadius(8)
            }
            
            // Quick Actions
            VStack(spacing: 8) {
                Button("View Detailed Results") {
                    showingAnalysisResults = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
                
                Button("Take Another Photo") {
                    selectedImage = nil
                    detectionViewModel.clearResults()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        VStack(spacing: 12) {
            if selectedImage == nil {
                Button(action: {
                    if cameraPermissionManager.permissionStatus == .authorized {
                        showingImageCapture = true
                    } else {
                        // Handle permission request
                    }
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Recent History View
    private var recentHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Analysis")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(userProfile.dentalHistory.suffix(3)) { result in
                        HistoryCard(result: result)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func analyzeImage() {
        guard let image = selectedImage else { return }
        
        Task {
            await detectionViewModel.analyzeImage(image)
            
            // Add to user history if analysis was successful
            if let result = detectionViewModel.analysisResult {
                userProfile.dentalHistory.append(result)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var trendIcon: String {
        switch userProfile.healthTrend {
        case .improving:
            return "arrow.up.circle.fill"
        case .stable:
            return "minus.circle.fill"
        case .declining:
            return "arrow.down.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch userProfile.healthTrend {
        case .improving:
            return .green
        case .stable:
            return .blue
        case .declining:
            return .red
        }
    }
    
    private func healthScoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100:
            return .green
        case 60...79:
            return .yellow
        case 40...59:
            return .orange
        default:
            return .red
        }
    }
    
    private func conditionColor(_ condition: DentalCondition) -> Color {
        switch condition.severity {
        case .none:
            return .green
        case .low:
            return .yellow
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AnalysisStepView: View {
    let title: String
    let description: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct HistoryCard: View {
    let result: DentalAnalysisResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(result.overallHealthScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(healthScoreColor)
                
                Spacer()
                
                Text(DateFormatter.shortDate.string(from: result.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.primaryCondition.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("\(Int(result.confidence * 100))% confidence")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 120)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var healthScoreColor: Color {
        switch result.overallHealthScore {
        case 80...100:
            return .green
        case 60...79:
            return .yellow
        case 40...59:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    ContentView()
}

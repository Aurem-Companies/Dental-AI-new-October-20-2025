import SwiftUI
import Charts

// MARK: - Main Content View
struct ContentView: View {
    
    // MARK: - State
    @StateObject private var detectionViewModel = DetectionViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @State private var selectedTab = 0
    @State private var showingImageAnalysis = false
    @State private var showingAbout = false
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(
                detectionViewModel: detectionViewModel,
                cameraPermissionManager: cameraPermissionManager,
                showingImageAnalysis: $showingImageAnalysis
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // History Tab
            HistoryView(detectionViewModel: detectionViewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView(
                showingAbout: $showingAbout,
                detectionViewModel: detectionViewModel
            )
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingImageAnalysis) {
            if let result = detectionViewModel.lastAnalysisResult {
                ImageAnalysisView(result: result)
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var detectionViewModel: DetectionViewModel
    @ObservedObject var cameraPermissionManager: CameraPermissionManager
    @Binding var showingImageAnalysis: Bool
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Quick Stats
                    quickStatsSection
                    
                    // Capture Button
                    captureSection
                    
                    // Recent Analysis
                    recentAnalysisSection
                    
                    // Tips Section
                    tipsSection
                }
                .padding()
            }
            .navigationTitle("🦷 DentalAI")
            .navigationBarTitleDisplayMode(.large)
        }
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Welcome to DentalAI")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Your AI-powered dental health companion")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Health Score",
                    value: "\(detectionViewModel.lastAnalysisResult?.healthScore ?? 0)",
                    color: .green,
                    icon: "heart.fill"
                )
                
                StatCard(
                    title: "Analyses",
                    value: "\(detectionViewModel.analysisHistory.count)",
                    color: .blue,
                    icon: "chart.bar.fill"
                )
                
                StatCard(
                    title: "Trend",
                    value: detectionViewModel.healthTrend.emoji,
                    color: detectionViewModel.healthTrend.color,
                    icon: "arrow.trending.up"
                )
            }
        }
    }
    
    // MARK: - Capture Section
    private var captureSection: some View {
        VStack(spacing: 16) {
            Text("📸 Capture & Analyze")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Button(action: {
                    if cameraPermissionManager.permissionStatus == .authorized {
                        showingCamera = true
                    } else {
                        cameraPermissionManager.requestPermission()
                    }
                }) {
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
                .disabled(cameraPermissionManager.permissionStatus == .denied)
                
                Button(action: {
                    showingPhotoLibrary = true
                }) {
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
            
            if cameraPermissionManager.permissionStatus == .denied {
                Text("Camera access denied. Please enable in Settings.")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Recent Analysis Section
    private var recentAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📋 Recent Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let lastResult = detectionViewModel.lastAnalysisResult {
                RecentAnalysisCard(result: lastResult) {
                    showingImageAnalysis = true
                }
            } else {
                Text("No recent analysis. Take a photo to get started!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Tips Section
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("💡 Daily Tips")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                TipCard(
                    icon: "🦷",
                    title: "Brush Twice Daily",
                    description: "Use fluoride toothpaste for 2 minutes each time"
                )
                
                TipCard(
                    icon: "🧵",
                    title: "Floss Daily",
                    description: "Clean between teeth to prevent plaque buildup"
                )
                
                TipCard(
                    icon: "💧",
                    title: "Stay Hydrated",
                    description: "Water helps wash away food particles and bacteria"
                )
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Recent Analysis Card
struct RecentAnalysisCard: View {
    let result: DentalAnalysisResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Health Score")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(result.healthScore)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(result.overallSeverity.emoji)
                            .font(.title2)
                        
                        Text(result.overallSeverity.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let primaryCondition = result.primaryCondition {
                    HStack {
                        Text(primaryCondition.emoji)
                        Text(primaryCondition.displayName)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(Int(result.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Tap to view details")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tip Card
struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - History View
struct HistoryView: View {
    @ObservedObject var detectionViewModel: DetectionViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(detectionViewModel.analysisHistory) { result in
                    HistoryRow(result: result)
                }
                .onDelete(perform: deleteAnalysis)
            }
            .navigationTitle("📋 History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func deleteAnalysis(offsets: IndexSet) {
        for index in offsets {
            let result = detectionViewModel.analysisHistory[index]
            detectionViewModel.deleteAnalysisResult(result)
        }
    }
}

// MARK: - History Row
struct HistoryRow: View {
    let result: DentalAnalysisResult
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(result.healthScore)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(result.overallSeverity.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(result.timestamp, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @Binding var showingAbout: Bool
    @ObservedObject var detectionViewModel: DetectionViewModel
    
    var body: some View {
        NavigationView {
            List {
                Section("Settings") {
                    NavigationLink(destination: UserProfileView()) {
                        Label("User Profile", systemImage: "person.circle")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell.circle")
                    }
                    
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy", systemImage: "lock.circle")
                    }
                }
                
                Section("Data") {
                    NavigationLink(destination: ExportDataView()) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink(destination: ImportDataView()) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }
                    
                    Button("Clear All Data") {
                        // Clear data action
                    }
                    .foregroundColor(.red)
                }
                
                Section("Support") {
                    Button("About DentalAI") {
                        showingAbout = true
                    }
                    
                    Button("Contact Support") {
                        // Contact support action
                    }
                    
                    Button("Rate App") {
                        // Rate app action
                    }
                }
            }
            .navigationTitle("👤 Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // App Info
                    VStack(spacing: 12) {
                        Text("🦷")
                            .font(.system(size: 60))
                        
                        Text("DentalAI")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("DentalAI is an AI-powered dental health monitoring app that helps you track your oral health using advanced computer vision and machine learning technologies.")
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "camera.fill", text: "AI-powered image analysis")
                            FeatureRow(icon: "chart.bar.fill", text: "Health score tracking")
                            FeatureRow(icon: "bell.fill", text: "Personalized recommendations")
                            FeatureRow(icon: "lock.fill", text: "Privacy-first design")
                            FeatureRow(icon: "heart.fill", text: "Health trend monitoring")
                        }
                    }
                    .padding()
                    
                    // Disclaimer
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Disclaimer")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("This app is for informational purposes only and should not replace professional dental consultation. Always consult with a qualified dentist for medical advice and treatment.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Placeholder Views
struct UserProfileView: View {
    var body: some View {
        Text("User Profile Settings")
            .navigationTitle("User Profile")
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification Settings")
            .navigationTitle("Notifications")
    }
}

struct PrivacySettingsView: View {
    var body: some View {
        Text("Privacy Settings")
            .navigationTitle("Privacy")
    }
}

struct ExportDataView: View {
    var body: some View {
        Text("Export Data")
            .navigationTitle("Export Data")
    }
}

struct ImportDataView: View {
    var body: some View {
        Text("Import Data")
            .navigationTitle("Import Data")
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

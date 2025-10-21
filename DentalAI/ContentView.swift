import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    
    // MARK: - State
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var detectionViewModel = DetectionViewModel()
    @StateObject private var cameraPermissionManager = CameraPermissionManager()
    @State private var selectedTab = 0
    @State private var showingImageAnalysis = false
    @State private var showingAbout = false
    
    // MARK: - Body
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                mainAppView
                        } else {
                AuthenticationView()
            }
        }
        .onAppear {
            print("🔍 ContentView appeared - isAuthenticated: \(authViewModel.isAuthenticated)")
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            print("🔄 Authentication state changed: \(isAuthenticated)")
        }
    }
    
    // MARK: - Main App View
    private var mainAppView: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ModernHomeView(
                detectionViewModel: detectionViewModel,
                cameraPermissionManager: cameraPermissionManager,
                showingImageAnalysis: $showingImageAnalysis
            )
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .accessibilityIdentifier("tab.home")
            .tag(0)
            
            // History Tab
            HistoryView(detectionViewModel: detectionViewModel)
                .tabItem {
                    Image(systemName: "clock.fill")
                    Text("History")
                }
                .accessibilityIdentifier("tab.history")
                .tag(1)
            
            // Profile Tab
            ProfileView(
                showingAbout: $showingAbout,
                detectionViewModel: detectionViewModel,
                authViewModel: authViewModel
            )
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .accessibilityIdentifier("tab.profile")
                .tag(2)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingImageAnalysis) {
            if let result = detectionViewModel.lastAnalysisResult {
                ImageAnalysisView(result: result)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                // Show loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing your photo...")
                        .font(.headline)
                    Text("This may take a few moments")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: showingImageAnalysis) { _, isShowing in
            print("🔬 ContentView: showingImageAnalysis changed to: \(isShowing)")
            if isShowing {
                if let result = detectionViewModel.lastAnalysisResult {
                    print("🔬 ContentView: Showing ImageAnalysisView with result - Health Score: \(result.healthScore)")
                } else {
                    print("🔬 ContentView: Showing loading state - no result yet")
                }
            }
        }
        .onChange(of: detectionViewModel.lastAnalysisResult) { _, result in
            print("🔬 ContentView: lastAnalysisResult changed - has result: \(result != nil)")
            if let result = result {
                print("🔬 ContentView: New result - Health Score: \(result.healthScore), Conditions: \(result.detectedConditions.count)")
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
    @State private var showingCropView = false
    @State private var capturedImage: UIImage?
    
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
        .sheet(isPresented: $showingCropView) {
            if let image = capturedImage {
                PhotoAdjustmentView(
                    originalImage: image,
                    detectionViewModel: detectionViewModel,
                    showingImageAnalysis: $showingImageAnalysis
                )
            } else {
                VStack(spacing: 20) {
                    Text("DEBUG: No image available")
                        .foregroundColor(.red)
                        .font(.headline)
                    
                    Text("showingCropView: \(showingCropView)")
                    Text("capturedImage is nil: \(capturedImage == nil)")
                    
                    Button("Dismiss") {
                        showingCropView = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                .cornerRadius(8)
                }
                .padding()
                .background(Color.yellow)
            }
        }
        .onChange(of: showingCropView) { _, isShowing in
            print("🔄 HomeView: showingCropView changed to: \(isShowing)")
            if isShowing {
                print("🔄 HomeView: capturedImage is nil: \(capturedImage == nil)")
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Welcome to DentalAI")
                .font(.title2)
                    .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityIdentifier("title.dentalai")
                
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
                    icon: "chart.line.uptrend.xyaxis"
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
                    .accessibilityIdentifier("btn.takePhoto")
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
                    .accessibilityIdentifier("btn.chooseLibrary")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Test button to show analysis view
                Button(action: {
                    print("🧪 Test button pressed - showing analysis view")
                    showingImageAnalysis = true
                }) {
                    HStack {
                        Image(systemName: "testtube.2")
                        Text("Test Analysis View")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
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
                
                HStack {
                    Text(result.primaryCondition.emoji)
                    Text(result.primaryCondition.displayName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(result.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if detectionViewModel.analysisHistory.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No Analysis History")
                            .font(.title2)
                .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Take your first photo to see your analysis history here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(detectionViewModel.analysisHistory) { result in
                            HistoryRow(result: result)
                        }
                        .onDelete(perform: deleteAnalysis)
                    }
                }
            }
            .navigationTitle("📋 History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !detectionViewModel.analysisHistory.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Clear All") {
                            showingClearAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .alert("Clear All History", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    clearAllHistory()
                }
            } message: {
                Text("This will permanently delete all your analysis history. This action cannot be undone.")
            }
        }
    }
    
    private func deleteAnalysis(offsets: IndexSet) {
        for index in offsets {
            let result = detectionViewModel.analysisHistory[index]
            detectionViewModel.deleteAnalysisResult(result)
        }
    }
    
    private func clearAllHistory() {
        // Permanently clear all analysis history
        detectionViewModel.clearAllAnalysisHistory()
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
    @ObservedObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                if let user = authViewModel.currentUser {
                    Section {
                        HStack {
                            Text("👤")
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                .font(.headline)
                                Text(user.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
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
                
                Section {
                    Button("Sign Out") {
                        authViewModel.signOut()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
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

// MARK: - Captivating Home View
struct ModernHomeView: View {
    @ObservedObject var detectionViewModel: DetectionViewModel
    @ObservedObject var cameraPermissionManager: CameraPermissionManager
    @Binding var showingImageAnalysis: Bool
    
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var showingCropView = false
    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var animateGradient = false
    @State private var pulseAnimation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Animated Background
                animatedBackground
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Hero Section
                        heroSection
                        
                        // Quick Actions with Premium Design
                        premiumQuickActions
                        
                        // Health Score Card with Animation
                        animatedHealthScoreCard
                        
                        // Recent Analysis with Glass Effect
                        glassRecentAnalysis
                        
                        // Premium Tips Section
                        premiumTipsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
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
        .sheet(isPresented: $showingCropView) {
            if let image = capturedImage {
                PhotoAdjustmentView(
                    originalImage: image,
                    detectionViewModel: detectionViewModel,
                    showingImageAnalysis: $showingImageAnalysis
                )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Premium UI Components
    private var animatedBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.4),
                    Color.pink.opacity(0.3),
                    Color.cyan.opacity(0.2)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            
            // Floating orbs
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: CGFloat.random(in: 80...150))
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.5),
                        value: animateGradient
                    )
            }
        }
        .ignoresSafeArea()
    }
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            HStack {
        VStack(alignment: .leading, spacing: 8) {
                    Text("DentalAI")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Your AI-powered dental health companion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 50
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    
                    Image(systemName: "mouth.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    private var premiumQuickActions: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Scan")
                    .font(.title2)
                    .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 20) {
                // Premium Camera Button
                Button(action: {
                    showingCamera = true
                }) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Take Photo")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Adjust & analyze")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue,
                                            Color.cyan,
                                            Color.blue.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 15, x: 0, y: 8)
                }
                
                // Premium Photo Library Button
                Button(action: {
                    showingPhotoLibrary = true
                }) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("From Library")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Choose existing")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.purple,
                                            Color.pink,
                                            Color.purple.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        }
                    )
                    .shadow(color: .purple.opacity(0.3), radius: 15, x: 0, y: 8)
                }
            }
        }
    }
    
    private var animatedHealthScoreCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Health Score")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(healthScoreColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20))
                        .foregroundColor(healthScoreColor)
                }
            }
            
            HStack(spacing: 24) {
                // Animated Score Display
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(healthScoreColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: CGFloat(currentHealthScore) / 100)
                        .stroke(
                            LinearGradient(
                                colors: [healthScoreColor, healthScoreColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: currentHealthScore)
                    
                    // Score text
                    VStack(spacing: 2) {
                        Text("\(currentHealthScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(healthScoreColor)
                        
                        Text("/ 100")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(healthScoreStatus)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(healthScoreColor)
                        
                        Text("Overall dental health")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Last checked")
                .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(lastCheckDate)
                            .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: healthScoreColor.opacity(0.2), radius: 20, x: 0, y: 10)
        )
    }
    
    private var glassRecentAnalysis: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Recent Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to history
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
            }
            
            if let lastResult = detectionViewModel.lastAnalysisResult {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Scan")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(DateFormatter.shortDate.string(from: lastResult.timestamp))
                                .font(.subheadline)
                .foregroundColor(.secondary)
        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.green)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(Array(lastResult.detectedConditions.prefix(3)), id: \.key) { condition, confidence in
                            HStack(spacing: 6) {
                                Text(condition.emoji)
                                    .font(.system(size: 16))
                                
                                Text("\(Int(confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(conditionColor(condition).opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(conditionColor(condition).opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        
                        Spacer()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Text("No analysis yet")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Take your first photo to get started!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)
                )
            }
        }
    }
    
    private var premiumTipsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Daily Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                PremiumTipCard(
                    icon: "paintbrush.fill",
                    title: "Brush for 2 minutes",
                    description: "Use a soft-bristled toothbrush and fluoride toothpaste",
                    color: .blue
                )
                
                PremiumTipCard(
                    icon: "line.3.horizontal",
                    title: "Floss daily",
                    description: "Clean between teeth to remove plaque and food particles",
                    color: .green
                )
                
                PremiumTipCard(
                    icon: "drop.fill",
                    title: "Stay hydrated",
                    description: "Drink plenty of water to maintain healthy saliva production",
                    color: .cyan
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    private var currentHealthScore: Int {
        return detectionViewModel.lastAnalysisResult?.healthScore ?? 75
    }
    
    private var healthScoreColor: Color {
        switch currentHealthScore {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }
    
    private var healthScoreStatus: String {
        switch currentHealthScore {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Needs Attention"
        }
    }
    
    private var lastCheckDate: String {
        if let lastResult = detectionViewModel.lastAnalysisResult {
            return DateFormatter.shortDate.string(from: lastResult.timestamp)
        }
        return "Never"
    }
    
    private func conditionColor(_ condition: DentalCondition) -> Color {
        switch condition {
        case .healthy: return .green
        case .cavity: return .red
        case .gingivitis: return .orange
        case .plaque: return .yellow
        case .tartar: return .brown
        case .discoloration: return .gray
        case .chippedTeeth: return .purple
        case .deadTooth: return .red
        case .misalignedTeeth: return .blue
        case .rootCanal: return .red
        }
    }
}


// MARK: - Premium Tip Card
struct PremiumTipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
    ContentView()
    }
}

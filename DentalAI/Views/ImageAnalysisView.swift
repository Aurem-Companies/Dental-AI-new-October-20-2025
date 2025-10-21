import SwiftUI
import Charts

// MARK: - Image Analysis View
struct ImageAnalysisView: View {
    let result: DentalAnalysisResult
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Bar
                tabBarSection
                
                // Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(0)
                    
                    recommendationsTab
                        .tag(1)
                    
                    detailsTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareButton(result: result)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Health Score Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result.healthScore) / 100)
                    .stroke(healthScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: result.healthScore)
                
                VStack {
                    Text("\(result.healthScore)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Health Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Overall Severity
            HStack {
                Text(result.overallSeverity.emoji)
                    .font(.title2)
                
                Text(result.overallSeverity.displayName)
                    .font(.headline)
                    .foregroundColor(result.overallSeverity.color)
            }
            
            // Analysis Info
            HStack(spacing: 20) {
                VStack {
                    Text("\(Int(result.confidence * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Confidence")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("\(Int(result.analysisDuration))s")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text(result.timestamp, style: .time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Tab Bar Section
    private var tabBarSection: some View {
        HStack(spacing: 0) {
            TabButton(title: "Overview", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            
            TabButton(title: "Recommendations", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            
            TabButton(title: "Details", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Detected Conditions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Detected Conditions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(Array(result.detectedConditions.keys.sorted { $0.displayName < $1.displayName }), id: \.self) { condition in
                            if let confidence = result.detectedConditions[condition] {
                                ConditionChip(
                                    condition: condition,
                                    confidence: confidence
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        QuickActionButton(
                            icon: "calendar",
                            title: "Schedule Appointment",
                            subtitle: "Book with a dentist",
                            color: .blue
                        )
                        
                        QuickActionButton(
                            icon: "heart.text.square",
                            title: "Track Progress",
                            subtitle: "Monitor your health",
                            color: .green
                        )
                        
                        QuickActionButton(
                            icon: "square.and.arrow.up",
                            title: "Share Results",
                            subtitle: "Send to your dentist",
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Health Trends Chart
                if !result.detectedConditions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Condition Confidence")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Chart {
                            ForEach(Array(result.detectedConditions.keys.sorted { $0.displayName < $1.displayName }), id: \.self) { condition in
                                if let confidence = result.detectedConditions[condition] {
                                    BarMark(
                                        x: .value("Condition", condition.displayName),
                                        y: .value("Confidence", confidence)
                                    )
                                    .foregroundStyle(condition.color)
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Recommendations Tab
    private var recommendationsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(result.recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Details Tab
    private var detailsTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Condition Explanations
                VStack(alignment: .leading, spacing: 16) {
                    Text("What These Results Mean")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(result.detectedConditions.keys.sorted { $0.displayName < $1.displayName }), id: \.self) { condition in
                        if let confidence = result.detectedConditions[condition] {
                            ConditionExplanationCard(condition: condition, confidence: confidence)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Analysis Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Analysis Summary")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        DetailRow(title: "Analysis Date", value: DateFormatter.shortDate.string(from: result.timestamp))
                        DetailRow(title: "Overall Confidence", value: "\(Int(result.confidence * 100))%")
                        DetailRow(title: "Analysis Time", value: String(format: "%.1f seconds", result.analysisDuration))
                        DetailRow(title: "Image Size", value: "\(Int(result.metadata.imageSize.width))x\(Int(result.metadata.imageSize.height))")
                        DetailRow(title: "Preprocessing Time", value: "\(String(format: "%.2f", result.metadata.preprocessingTime))s")
                        DetailRow(title: "Inference Time", value: "\(String(format: "%.2f", result.metadata.inferenceTime))s")
                        DetailRow(title: "Postprocessing Time", value: "\(String(format: "%.2f", result.metadata.postprocessingTime))s")
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                
                // Condition Details
                if !result.detectedConditions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Condition Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            ForEach(Array(result.detectedConditions.keys.sorted { $0.displayName < $1.displayName }), id: \.self) { condition in
                                if let confidence = result.detectedConditions[condition] {
                                    ConditionDetailRow(
                                        condition: condition,
                                        confidence: confidence
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var healthScoreColor: Color {
        switch result.healthScore {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Rectangle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

// MARK: - Condition Chip
struct ConditionChip: View {
    let condition: DentalCondition
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 8) {
            Text(condition.emoji)
                .font(.title2)
            
            Text(condition.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(condition.color.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(condition.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: Recommendation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(recommendation.category.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(recommendation.category.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(recommendation.priority.displayName)
                        .font(.caption)
                        .foregroundColor(recommendation.priority.color)
                }
                
                Spacer()
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(recommendation.personalizedText)
                .font(.body)
                .foregroundColor(.primary)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Action Items
                    if !recommendation.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Action Items:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(recommendation.actionItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(item)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    
                    // Timeframe
                    HStack {
                        Text("Timeframe:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(recommendation.timeframe)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Estimated Cost
                    if let cost = recommendation.estimatedCost {
                        HStack {
                            Text("Estimated Cost:")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("$\(Int(cost))")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(recommendation.category.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Condition Detail Row
struct ConditionDetailRow: View {
    let condition: DentalCondition
    let confidence: Double
    
    var body: some View {
        HStack {
            Text(condition.emoji)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(condition.displayName)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(condition.severity.displayName)
                    .font(.caption)
                    .foregroundColor(condition.severity.color)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(confidence * 100))%")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Condition Explanation Card
struct ConditionExplanationCard: View {
    let condition: DentalCondition
    let confidence: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(condition.emoji)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(condition.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(Int(confidence * 100))% detected")
                        .font(.subheadline)
                        .foregroundColor(confidenceColor)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            Text(conditionExplanation)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        case 0.4..<0.6: return .yellow
        default: return .red
        }
    }
    
    private var conditionExplanation: String {
        switch condition {
        case .cavity:
            return "A cavity is a hole in your tooth caused by tooth decay. The \(Int(confidence * 100))% means our AI is \(Int(confidence * 100))% confident it detected signs of decay. Early treatment prevents further damage."
        case .gingivitis:
            return "Gingivitis is early gum disease causing inflammation. The \(Int(confidence * 100))% indicates how likely we detected red, swollen gums. Good news: it's reversible with proper care!"
        case .plaque:
            return "Plaque is a sticky film of bacteria on teeth. The \(Int(confidence * 100))% shows how confident we are about detecting this buildup. Regular brushing and flossing can remove it."
        case .tartar:
            return "Tartar is hardened plaque that can't be removed by brushing. The \(Int(confidence * 100))% indicates detection confidence. Professional cleaning is needed to remove it."
        case .discoloration:
            return "Tooth discoloration can be from stains, aging, or other factors. The \(Int(confidence * 100))% shows how likely we detected color changes. Professional whitening can help."
        case .chippedTeeth:
            return "A chipped tooth has a small piece broken off. The \(Int(confidence * 100))% indicates detection confidence. Small chips may need cosmetic treatment."
        case .healthy:
            return "Healthy teeth show no signs of decay or disease. The \(Int(confidence * 100))% means we're confident your teeth look good! Keep up your current oral care routine."
        case .deadTooth:
            return "A dead tooth has lost its blood supply and nerve. The \(Int(confidence * 100))% shows detection confidence. This usually requires root canal treatment."
        case .misalignedTeeth:
            return "Misaligned teeth are crooked or don't fit together properly. The \(Int(confidence * 100))% indicates how likely we detected alignment issues. Orthodontic treatment can help."
        case .rootCanal:
            return "Root canal treatment is needed for infected tooth pulp. The \(Int(confidence * 100))% shows detection confidence. This procedure saves the tooth from extraction."
        }
    }
}

// MARK: - Share Button
struct ShareButton: View {
    let result: DentalAnalysisResult
    @State private var showingShareSheet = false
    @State private var exportedImage: UIImage?
    
    var body: some View {
        Button(action: {
            exportAndShare()
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let image = exportedImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    private func exportAndShare() {
        // Convert detections to DetectionBox format
        let imageSize = CGSize(width: 1000, height: 1000) // Placeholder size
        let bounds = CGRect(origin: .zero, size: imageSize)
        
        let detections = result.detectedConditions.compactMap { (condition, confidence) -> DetectionBox? in
            // Create a simple bounding box for each detection
            // In a real implementation, you'd get actual bounding boxes from the detection service
            let rect = CGRect(x: 50, y: 50, width: 100, height: 100) // Placeholder
            
            // Clamp to image bounds; drop invalids
            let r = rect.integral.intersection(bounds)
            guard r.width > 0, r.height > 0, r.isFinite else { return nil }
            
            return DetectionBox(rect: r, label: condition.displayName, confidence: Float(confidence))
        }
        
        // Create a placeholder image (in real implementation, use the actual analyzed image)
        let placeholderImage = UIImage(systemName: "photo") ?? UIImage()
        
        // Export the image with detections
        exportedImage = ResultExporter.render(
            image: placeholderImage,
            detections: detections,
            modelVersion: "v1.0",
            date: result.timestamp
        )
        
        showingShareSheet = true
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview
struct ImageAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleResult = DentalAnalysisResult(
            healthScore: 75,
            detectedConditions: [
                .healthy: 0.8,
                .discoloration: 0.6,
                .plaque: 0.4
            ],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.5,
            confidence: 0.7,
            recommendations: [
                Recommendation(
                    category: .homeCare,
                    priority: .medium,
                    actionItems: ["Brush twice daily", "Use fluoride toothpaste"],
                    personalizedText: "Your dental health is good but can be improved with proper care.",
                    timeframe: "Daily"
                )
            ]
        )
        
        ImageAnalysisView(result: sampleResult)
    }
}

// MARK: - CGRect Extension
private extension CGRect {
    var isFinite: Bool {
        [origin.x, origin.y, size.width, size.height].allSatisfy { $0.isFinite && !$0.isNaN }
    }
}
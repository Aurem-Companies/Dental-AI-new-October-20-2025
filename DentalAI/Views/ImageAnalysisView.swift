import SwiftUI

struct ImageAnalysisView: View {
    let analysisResult: DentalAnalysisResult
    @State private var selectedTab = 0
    @State private var showingRecommendations = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView
                    
                    // Image and Results
                    imageAndResultsView
                    
                    // Tabs
                    tabView
                    
                    // Content based on selected tab
                    tabContentView
                }
                .padding()
            }
            .navigationTitle("Analysis Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Health Score
            HStack {
                VStack(alignment: .leading) {
                    Text("Overall Health Score")
                        .font(.headline)
                    Text("\(analysisResult.overallHealthScore)/100")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(healthScoreColor)
                }
                
                Spacer()
                
                // Confidence
                VStack(alignment: .trailing) {
                    Text("Confidence")
                        .font(.headline)
                    Text("\(Int(analysisResult.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Severity Indicator
            HStack {
                Image(systemName: severityIcon)
                    .foregroundColor(severityColor)
                Text("Severity: \(analysisResult.severity.rawValue)")
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)
                Spacer()
            }
            .padding()
            .background(severityColor.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Image and Results View
    private var imageAndResultsView: some View {
        VStack(spacing: 16) {
            // Image
            if let image = analysisResult.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            }
            
            // Detected Conditions
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Conditions")
                    .font(.headline)
                    .padding(.horizontal)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(analysisResult.conditions) { condition in
                        ConditionChip(condition: condition)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Tab View
    private var tabView: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Overview",
                isSelected: selectedTab == 0,
                action: { selectedTab = 0 }
            )
            
            TabButton(
                title: "Recommendations",
                isSelected: selectedTab == 1,
                action: { selectedTab = 1 }
            )
            
            TabButton(
                title: "Details",
                isSelected: selectedTab == 2,
                action: { selectedTab = 2 }
            )
        }
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // MARK: - Tab Content View
    private var tabContentView: some View {
        Group {
            switch selectedTab {
            case 0:
                overviewContent
            case 1:
                recommendationsContent
            case 2:
                detailsContent
            default:
                overviewContent
            }
        }
        .animation(.easeInOut, value: selectedTab)
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Primary Condition
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary Condition")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(conditionColor(analysisResult.primaryCondition))
                    
                    Text(analysisResult.primaryCondition.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                .padding()
                .background(conditionColor(analysisResult.primaryCondition).opacity(0.1))
                .cornerRadius(8)
                
                Text(analysisResult.primaryCondition.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Analysis Summary
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis Summary")
                    .font(.headline)
                
                Text("Based on the image analysis, \(analysisSummary)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 8) {
                Text("Quick Actions")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    QuickActionButton(
                        title: "View Recommendations",
                        icon: "list.bullet",
                        action: { selectedTab = 1 }
                    )
                    
                    QuickActionButton(
                        title: "Schedule Appointment",
                        icon: "calendar",
                        action: { /* Handle appointment scheduling */ }
                    )
                    
                    QuickActionButton(
                        title: "Share Results",
                        icon: "square.and.arrow.up",
                        action: { /* Handle sharing */ }
                    )
                }
            }
        }
    }
    
    // MARK: - Recommendations Content
    private var recommendationsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recommendations")
                .font(.headline)
            
            ForEach(analysisResult.recommendations) { recommendation in
                RecommendationCard(recommendation: recommendation)
            }
        }
    }
    
    // MARK: - Details Content
    private var detailsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Analysis Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Analysis Details")
                    .font(.headline)
                
                DetailRow(title: "Analysis Date", value: DateFormatter.shortDate.string(from: analysisResult.timestamp))
                DetailRow(title: "Confidence Level", value: "\(Int(analysisResult.confidence * 100))%")
                DetailRow(title: "Conditions Detected", value: "\(analysisResult.conditions.count)")
                DetailRow(title: "Overall Severity", value: analysisResult.severity.rawValue)
            }
            
            // Condition Details
            VStack(alignment: .leading, spacing: 8) {
                Text("Condition Details")
                    .font(.headline)
                
                ForEach(analysisResult.conditions) { condition in
                    ConditionDetailRow(condition: condition)
                }
            }
            
            // Technical Information
            VStack(alignment: .leading, spacing: 8) {
                Text("Technical Information")
                    .font(.headline)
                
                Text("This analysis was performed using advanced computer vision algorithms and rule-based detection systems. Results are for informational purposes only and should not replace professional dental consultation.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var healthScoreColor: Color {
        switch analysisResult.overallHealthScore {
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
    
    private var severityColor: Color {
        switch analysisResult.severity {
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
    
    private var severityIcon: String {
        switch analysisResult.severity {
        case .none:
            return "checkmark.circle.fill"
        case .low:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.triangle.fill"
        case .high:
            return "xmark.circle.fill"
        }
    }
    
    private var analysisSummary: String {
        if analysisResult.conditions.contains(.healthy) && analysisResult.conditions.count == 1 {
            return "your teeth appear to be in good health with no significant issues detected."
        } else if analysisResult.conditions.count == 1 {
            return "a potential \(analysisResult.primaryCondition.rawValue.lowercased()) was detected that may require attention."
        } else {
            return "multiple dental conditions were detected that may require professional evaluation."
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
struct ConditionChip: View {
    let condition: DentalCondition
    
    var body: some View {
        HStack {
            Image(systemName: conditionIcon)
                .foregroundColor(conditionColor)
            Text(condition.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(conditionColor.opacity(0.1))
        .foregroundColor(conditionColor)
        .cornerRadius(16)
    }
    
    private var conditionColor: Color {
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
    
    private var conditionIcon: String {
        switch condition {
        case .cavity:
            return "circle.dotted"
        case .gingivitis:
            return "heart.fill"
        case .discoloration:
            return "paintbrush.fill"
        case .plaque:
            return "circle.fill"
        case .tartar:
            return "circle.grid.2x2.fill"
        case .deadTooth:
            return "xmark.circle.fill"
        case .rootCanal:
            return "wrench.fill"
        case .chipped:
            return "scissors"
        case .misaligned:
            return "arrow.left.and.right"
        case .healthy:
            return "checkmark.circle.fill"
        }
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.clear)
                .cornerRadius(8)
        }
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: priorityIcon)
                    .foregroundColor(priorityColor)
                
                Text(recommendation.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .cornerRadius(8)
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            if !recommendation.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Items:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(recommendation.actionItems, id: \.self) { item in
                        HStack(alignment: .top) {
                            Text("•")
                                .foregroundColor(.blue)
                            Text(item)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .immediate:
            return .red
        case .urgent:
            return .orange
        case .important:
            return .yellow
        case .general:
            return .blue
        }
    }
    
    private var priorityIcon: String {
        switch recommendation.priority {
        case .immediate:
            return "exclamationmark.triangle.fill"
        case .urgent:
            return "clock.fill"
        case .important:
            return "star.fill"
        case .general:
            return "info.circle.fill"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct ConditionDetailRow: View {
    let condition: DentalCondition
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(condition.rawValue)
                    .fontWeight(.medium)
                Spacer()
                Text(condition.severity.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .foregroundColor(severityColor)
                    .cornerRadius(4)
            }
            
            Text(condition.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var severityColor: Color {
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

// MARK: - Extensions
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    ImageAnalysisView(analysisResult: DentalAnalysisResult(
        conditions: [.cavity, .gingivitis],
        confidence: 0.85,
        severity: .medium,
        recommendations: [
            Recommendation(
                title: "Schedule Dental Appointment",
                description: "Cavities require professional treatment.",
                priority: .immediate,
                category: .professional,
                actionItems: ["Call your dentist", "Avoid sugary foods"]
            )
        ],
        timestamp: Date(),
        image: nil
    ))
}

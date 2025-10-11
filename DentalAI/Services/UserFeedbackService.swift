import Foundation
import UIKit

// MARK: - User Feedback Service Protocol
protocol UserFeedbackServiceProtocol {
    func submitFeedback(for result: DentalAnalysisResult, userRating: Int, comments: String?) async throws
    func getFeedbackHistory() -> [UserFeedback]
    func clearFeedbackHistory()
}

// MARK: - User Feedback Service Implementation
class UserFeedbackService: ObservableObject, UserFeedbackServiceProtocol {
    
    // MARK: - Properties
    @Published var feedbackHistory: [UserFeedback] = []
    private let dataManager = DataManager.shared
    
    // MARK: - Initialization
    init() {
        loadFeedbackHistory()
    }
    
    // MARK: - Feedback Submission
    func submitFeedback(for result: DentalAnalysisResult, userRating: Int, comments: String?) async throws {
        let feedback = UserFeedback(
            analysisResultId: result.id,
            userRating: userRating,
            comments: comments,
            timestamp: Date(),
            conditions: result.conditions,
            confidence: result.confidence
        )
        
        // Validate feedback
        try validateFeedback(feedback)
        
        // Store feedback locally
        await MainActor.run {
            feedbackHistory.append(feedback)
            saveFeedbackHistory()
        }
        
        // In a real app, you would also send this to a server for ML improvement
        try await sendFeedbackToServer(feedback)
    }
    
    // MARK: - Feedback History
    func getFeedbackHistory() -> [UserFeedback] {
        return feedbackHistory
    }
    
    func clearFeedbackHistory() {
        feedbackHistory.removeAll()
        saveFeedbackHistory()
    }
    
    // MARK: - Analytics
    func getFeedbackAnalytics() -> FeedbackAnalytics {
        let totalFeedback = feedbackHistory.count
        let averageRating = feedbackHistory.isEmpty ? 0.0 : Double(feedbackHistory.map { $0.userRating }.reduce(0, +)) / Double(totalFeedback)
        
        let conditionAccuracy = calculateConditionAccuracy()
        let confidenceCorrelation = calculateConfidenceCorrelation()
        
        return FeedbackAnalytics(
            totalFeedback: totalFeedback,
            averageRating: averageRating,
            conditionAccuracy: conditionAccuracy,
            confidenceCorrelation: confidenceCorrelation,
            lastFeedbackDate: feedbackHistory.last?.timestamp
        )
    }
    
    // MARK: - ML Improvement
    func getMLImprovementData() -> MLImprovementData {
        let highConfidenceFeedback = feedbackHistory.filter { $0.confidence > 0.8 }
        let lowConfidenceFeedback = feedbackHistory.filter { $0.confidence < 0.5 }
        
        let conditionMappings = createConditionMappings()
        let userCorrections = identifyUserCorrections()
        
        return MLImprovementData(
            highConfidenceFeedback: highConfidenceFeedback,
            lowConfidenceFeedback: lowConfidenceFeedback,
            conditionMappings: conditionMappings,
            userCorrections: userCorrections
        )
    }
    
    // MARK: - Private Methods
    private func validateFeedback(_ feedback: UserFeedback) throws {
        if feedback.userRating < 1 || feedback.userRating > 5 {
            throw ValidationError.outOfRange("User rating must be between 1 and 5")
        }
        
        if let comments = feedback.comments, comments.count > 1000 {
            throw ValidationError.outOfRange("Comments cannot exceed 1000 characters")
        }
    }
    
    private func sendFeedbackToServer(_ feedback: UserFeedback) async throws {
        // In a real implementation, this would send feedback to a server
        // For now, we'll simulate the network call
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Simulate potential network error
        if Int.random(in: 1...100) <= 5 { // 5% chance of failure
            throw AnalysisError.networkError("Failed to send feedback to server")
        }
    }
    
    private func loadFeedbackHistory() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "feedbackHistory"),
           let history = try? JSONDecoder().decode([UserFeedback].self, from: data) {
            feedbackHistory = history
        }
    }
    
    private func saveFeedbackHistory() {
        if let data = try? JSONEncoder().encode(feedbackHistory) {
            UserDefaults.standard.set(data, forKey: "feedbackHistory")
        }
    }
    
    private func calculateConditionAccuracy() -> [DentalCondition: Double] {
        var accuracy: [DentalCondition: Double] = [:]
        
        for condition in DentalCondition.allCases {
            let conditionFeedback = feedbackHistory.filter { $0.conditions.contains(condition) }
            if !conditionFeedback.isEmpty {
                let correctPredictions = conditionFeedback.filter { $0.userRating >= 4 }.count
                accuracy[condition] = Double(correctPredictions) / Double(conditionFeedback.count)
            }
        }
        
        return accuracy
    }
    
    private func calculateConfidenceCorrelation() -> Double {
        guard feedbackHistory.count > 1 else { return 0.0 }
        
        let ratings = feedbackHistory.map { Double($0.userRating) }
        let confidences = feedbackHistory.map { $0.confidence }
        
        // Simple correlation calculation
        let meanRating = ratings.reduce(0, +) / Double(ratings.count)
        let meanConfidence = confidences.reduce(0, +) / Double(confidences.count)
        
        var numerator = 0.0
        var denominatorRating = 0.0
        var denominatorConfidence = 0.0
        
        for i in 0..<ratings.count {
            let ratingDiff = ratings[i] - meanRating
            let confidenceDiff = confidences[i] - meanConfidence
            
            numerator += ratingDiff * confidenceDiff
            denominatorRating += ratingDiff * ratingDiff
            denominatorConfidence += confidenceDiff * confidenceDiff
        }
        
        let denominator = sqrt(denominatorRating * denominatorConfidence)
        return denominator == 0 ? 0.0 : numerator / denominator
    }
    
    private func createConditionMappings() -> [DentalCondition: [String]] {
        var mappings: [DentalCondition: [String]] = [:]
        
        for condition in DentalCondition.allCases {
            let conditionFeedback = feedbackHistory.filter { $0.conditions.contains(condition) }
            let comments = conditionFeedback.compactMap { $0.comments }.filter { !$0.isEmpty }
            mappings[condition] = comments
        }
        
        return mappings
    }
    
    private func identifyUserCorrections() -> [UserCorrection] {
        var corrections: [UserCorrection] = []
        
        for feedback in feedbackHistory {
            if feedback.userRating <= 2 && feedback.comments != nil {
                // Low rating with comments suggests a correction
                let correction = UserCorrection(
                    originalConditions: feedback.conditions,
                    userRating: feedback.userRating,
                    userComments: feedback.comments ?? "",
                    timestamp: feedback.timestamp
                )
                corrections.append(correction)
            }
        }
        
        return corrections
    }
}

// MARK: - Supporting Types
struct UserFeedback: Identifiable, Codable {
    let id = UUID()
    let analysisResultId: UUID
    let userRating: Int // 1-5 scale
    let comments: String?
    let timestamp: Date
    let conditions: [DentalCondition]
    let confidence: Double
    
    var isPositive: Bool {
        userRating >= 4
    }
    
    var isNegative: Bool {
        userRating <= 2
    }
}

struct FeedbackAnalytics {
    let totalFeedback: Int
    let averageRating: Double
    let conditionAccuracy: [DentalCondition: Double]
    let confidenceCorrelation: Double
    let lastFeedbackDate: Date?
    
    var overallAccuracy: Double {
        let accuracies = conditionAccuracy.values
        return accuracies.isEmpty ? 0.0 : accuracies.reduce(0, +) / Double(accuracies.count)
    }
    
    var isConfidenceReliable: Bool {
        abs(confidenceCorrelation) > 0.3
    }
}

struct MLImprovementData {
    let highConfidenceFeedback: [UserFeedback]
    let lowConfidenceFeedback: [UserFeedback]
    let conditionMappings: [DentalCondition: [String]]
    let userCorrections: [UserCorrection]
    
    var improvementAreas: [DentalCondition] {
        // Identify conditions with low accuracy or many corrections
        var areas: [DentalCondition] = []
        
        for (condition, corrections) in conditionMappings {
            if corrections.count > 3 { // Many comments suggest issues
                areas.append(condition)
            }
        }
        
        return areas
    }
}

struct UserCorrection: Identifiable {
    let id = UUID()
    let originalConditions: [DentalCondition]
    let userRating: Int
    let userComments: String
    let timestamp: Date
    
    var suggestedConditions: [DentalCondition] {
        // Parse user comments to suggest corrected conditions
        // This is a simplified implementation
        var conditions: [DentalCondition] = []
        
        let comments = userComments.lowercased()
        
        if comments.contains("cavity") || comments.contains("decay") {
            conditions.append(.cavity)
        }
        if comments.contains("gum") || comments.contains("gingivitis") {
            conditions.append(.gingivitis)
        }
        if comments.contains("discolor") || comments.contains("stain") {
            conditions.append(.discoloration)
        }
        if comments.contains("healthy") || comments.contains("good") {
            conditions.append(.healthy)
        }
        
        return conditions.isEmpty ? [.healthy] : conditions
    }
}

// MARK: - Extensions
extension UserFeedbackService {
    
    // MARK: - Export/Import
    func exportFeedbackData() -> Data? {
        let exportData = FeedbackExportData(
            feedbackHistory: feedbackHistory,
            analytics: getFeedbackAnalytics(),
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importFeedbackData(_ data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(FeedbackExportData.self, from: data) else {
            return false
        }
        
        feedbackHistory = importData.feedbackHistory
        saveFeedbackHistory()
        
        return true
    }
}

struct FeedbackExportData: Codable {
    let feedbackHistory: [UserFeedback]
    let analytics: FeedbackAnalytics
    let exportDate: Date
}

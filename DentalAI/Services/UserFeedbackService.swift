import Foundation
import UIKit
import SwiftUI

// MARK: - User Feedback Service
class UserFeedbackService: ObservableObject {
    
    // MARK: - Properties
    static let shared = UserFeedbackService()
    private let dataManager = DataManager.shared
    private let logger = Logger(subsystem: "com.dentalai.app", category: "UserFeedback")
    
    @Published var feedbackHistory: [UserFeedback] = []
    @Published var pendingFeedback: [UserFeedback] = []
    
    // MARK: - Initialization
    private init() {
        loadFeedbackHistory()
    }
    
    // MARK: - Feedback Submission
    func submitFeedback(_ feedback: UserFeedback) async throws {
        // Validate feedback
        guard validateFeedback(feedback) else {
            throw FeedbackError.invalidFeedback
        }
        
        // Add to pending feedback
        await MainActor.run {
            pendingFeedback.append(feedback)
        }
        
        // Process feedback
        try await processFeedback(feedback)
        
        // Move to history
        await MainActor.run {
            pendingFeedback.removeAll { $0.id == feedback.id }
            feedbackHistory.insert(feedback, at: 0)
            
            // Keep only last 100 feedback items
            if feedbackHistory.count > 100 {
                feedbackHistory = Array(feedbackHistory.prefix(100))
            }
        }
        
        // Save to data manager
        saveFeedbackHistory()
        
        logger.info("Feedback submitted successfully: \(feedback.type.rawValue)")
    }
    
    // MARK: - Feedback Processing
    private func processFeedback(_ feedback: UserFeedback) async throws {
        switch feedback.type {
        case .bugReport:
            try await processBugReport(feedback)
        case .featureRequest:
            try await processFeatureRequest(feedback)
        case .rating:
            try await processRating(feedback)
        case .general:
            try await processGeneralFeedback(feedback)
        case .analysisAccuracy:
            try await processAnalysisAccuracyFeedback(feedback)
        }
    }
    
    private func processBugReport(_ feedback: UserFeedback) async throws {
        // Log bug report
        logger.warning("Bug Report: \(feedback.message)")
        
        // Add system information
        let systemInfo = getSystemInfo()
        feedback.systemInfo = systemInfo
        
        // Could send to crash reporting service
        // await sendToCrashReportingService(feedback)
    }
    
    private func processFeatureRequest(_ feedback: UserFeedback) async throws {
        // Log feature request
        logger.info("Feature Request: \(feedback.message)")
        
        // Could send to product management
        // await sendToProductManagement(feedback)
    }
    
    private func processRating(_ feedback: UserFeedback) async throws {
        // Log rating
        logger.info("User Rating: \(feedback.rating ?? 0)")
        
        // Could send to analytics service
        // await sendToAnalytics(feedback)
    }
    
    private func processGeneralFeedback(_ feedback: UserFeedback) async throws {
        // Log general feedback
        logger.info("General Feedback: \(feedback.message)")
    }
    
    private func processAnalysisAccuracyFeedback(_ feedback: UserFeedback) async throws {
        // Log analysis accuracy feedback
        logger.info("Analysis Accuracy Feedback: \(feedback.message)")
        
        // This could be used to improve ML models
        // await sendToMLImprovementService(feedback)
    }
    
    // MARK: - Feedback Validation
    private func validateFeedback(_ feedback: UserFeedback) -> Bool {
        // Check message length
        if feedback.message.count < 10 {
            return false
        }
        
        if feedback.message.count > 1000 {
            return false
        }
        
        // Check rating range
        if let rating = feedback.rating {
            if rating < 1 || rating > 5 {
                return false
            }
        }
        
        // Check for spam/inappropriate content
        if containsInappropriateContent(feedback.message) {
            return false
        }
        
        return true
    }
    
    private func containsInappropriateContent(_ message: String) -> Bool {
        let inappropriateWords = ["spam", "scam", "fake", "hack", "virus"]
        let lowercasedMessage = message.lowercased()
        
        return inappropriateWords.contains { lowercasedMessage.contains($0) }
    }
    
    // MARK: - Feedback History Management
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
    
    // MARK: - System Information
    private func getSystemInfo() -> SystemInfo {
        return SystemInfo(
            deviceModel: UIDevice.current.model,
            systemVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            locale: Locale.current.identifier,
            timeZone: TimeZone.current.identifier,
            timestamp: Date()
        )
    }
    
    // MARK: - Feedback Analytics
    func getFeedbackAnalytics() -> FeedbackAnalytics {
        let totalFeedback = feedbackHistory.count
        let bugReports = feedbackHistory.filter { $0.type == .bugReport }.count
        let featureRequests = feedbackHistory.filter { $0.type == .featureRequest }.count
        let ratings = feedbackHistory.filter { $0.type == .rating }.count
        let generalFeedback = feedbackHistory.filter { $0.type == .general }.count
        let analysisAccuracy = feedbackHistory.filter { $0.type == .analysisAccuracy }.count
        
        let averageRating = feedbackHistory.compactMap { $0.rating }.reduce(0, +) / Double(feedbackHistory.compactMap { $0.rating }.count)
        
        return FeedbackAnalytics(
            totalFeedback: totalFeedback,
            bugReports: bugReports,
            featureRequests: featureRequests,
            ratings: ratings,
            generalFeedback: generalFeedback,
            analysisAccuracy: analysisAccuracy,
            averageRating: averageRating,
            feedbackTrend: calculateFeedbackTrend()
        )
    }
    
    private func calculateFeedbackTrend() -> FeedbackTrend {
        guard feedbackHistory.count >= 2 else { return .stable }
        
        let recentFeedback = Array(feedbackHistory.prefix(5))
        let olderFeedback = Array(feedbackHistory.suffix(5))
        
        let recentCount = recentFeedback.count
        let olderCount = olderFeedback.count
        
        if recentCount > olderCount {
            return .increasing
        } else if recentCount < olderCount {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Feedback Categories
    func getFeedbackByCategory(_ category: FeedbackCategory) -> [UserFeedback] {
        return feedbackHistory.filter { $0.category == category }
    }
    
    func getFeedbackByType(_ type: FeedbackType) -> [UserFeedback] {
        return feedbackHistory.filter { $0.type == type }
    }
    
    func getFeedbackByRating(_ rating: Int) -> [UserFeedback] {
        return feedbackHistory.filter { $0.rating == rating }
    }
    
    // MARK: - Feedback Search
    func searchFeedback(query: String) -> [UserFeedback] {
        guard !query.isEmpty else { return feedbackHistory }
        
        return feedbackHistory.filter { feedback in
            feedback.message.lowercased().contains(query.lowercased()) ||
            feedback.category.displayName.lowercased().contains(query.lowercased()) ||
            feedback.type.displayName.lowercased().contains(query.lowercased())
        }
    }
    
    // MARK: - Feedback Export
    func exportFeedback() -> Data? {
        let exportData = FeedbackExport(
            feedbackHistory: feedbackHistory,
            analytics: getFeedbackAnalytics(),
            exportDate: Date(),
            version: "1.0"
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    // MARK: - Feedback Import
    func importFeedback(from data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(FeedbackExport.self, from: data) else {
            return false
        }
        
        feedbackHistory = importData.feedbackHistory
        saveFeedbackHistory()
        
        return true
    }
    
    // MARK: - Feedback Response
    func respondToFeedback(_ feedback: UserFeedback, response: String) async throws {
        feedback.response = response
        feedback.responseDate = Date()
        
        // Update in history
        if let index = feedbackHistory.firstIndex(where: { $0.id == feedback.id }) {
            feedbackHistory[index] = feedback
            saveFeedbackHistory()
        }
        
        logger.info("Response added to feedback: \(feedback.id)")
    }
    
    // MARK: - Feedback Status
    func updateFeedbackStatus(_ feedback: UserFeedback, status: FeedbackStatus) {
        feedback.status = status
        
        // Update in history
        if let index = feedbackHistory.firstIndex(where: { $0.id == feedback.id }) {
            feedbackHistory[index] = feedback
            saveFeedbackHistory()
        }
    }
    
    // MARK: - Feedback Cleanup
    func clearOldFeedback(olderThan days: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        feedbackHistory.removeAll { $0.timestamp < cutoffDate }
        saveFeedbackHistory()
    }
    
    func clearAllFeedback() {
        feedbackHistory.removeAll()
        pendingFeedback.removeAll()
        saveFeedbackHistory()
    }
}

// MARK: - Supporting Types
struct UserFeedback: Codable, Identifiable {
    let id = UUID()
    let type: FeedbackType
    let category: FeedbackCategory
    let message: String
    let rating: Int?
    let timestamp: Date
    var status: FeedbackStatus
    var response: String?
    var responseDate: Date?
    var systemInfo: SystemInfo?
    
    init(type: FeedbackType, category: FeedbackCategory, message: String, rating: Int? = nil, status: FeedbackStatus = .pending) {
        self.type = type
        self.category = category
        self.message = message
        self.rating = rating
        self.timestamp = Date()
        self.status = status
    }
}

enum FeedbackType: String, CaseIterable, Codable {
    case bugReport = "bug_report"
    case featureRequest = "feature_request"
    case rating = "rating"
    case general = "general"
    case analysisAccuracy = "analysis_accuracy"
    
    var displayName: String {
        switch self {
        case .bugReport: return "Bug Report"
        case .featureRequest: return "Feature Request"
        case .rating: return "Rating"
        case .general: return "General Feedback"
        case .analysisAccuracy: return "Analysis Accuracy"
        }
    }
    
    var emoji: String {
        switch self {
        case .bugReport: return "🐛"
        case .featureRequest: return "💡"
        case .rating: return "⭐"
        case .general: return "💬"
        case .analysisAccuracy: return "🎯"
        }
    }
}

enum FeedbackCategory: String, CaseIterable, Codable {
    case ui = "ui"
    case performance = "performance"
    case accuracy = "accuracy"
    case usability = "usability"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .ui: return "User Interface"
        case .performance: return "Performance"
        case .accuracy: return "Accuracy"
        case .usability: return "Usability"
        case .other: return "Other"
        }
    }
    
    var emoji: String {
        switch self {
        case .ui: return "🎨"
        case .performance: return "⚡"
        case .accuracy: return "🎯"
        case .usability: return "👥"
        case .other: return "📝"
        }
    }
}

enum FeedbackStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case resolved = "resolved"
    case closed = "closed"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        case .closed: return "Closed"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        case .closed: return .gray
        }
    }
}

struct SystemInfo: Codable {
    let deviceModel: String
    let systemVersion: String
    let appVersion: String
    let buildNumber: String
    let locale: String
    let timeZone: String
    let timestamp: Date
}

struct FeedbackAnalytics {
    let totalFeedback: Int
    let bugReports: Int
    let featureRequests: Int
    let ratings: Int
    let generalFeedback: Int
    let analysisAccuracy: Int
    let averageRating: Double
    let feedbackTrend: FeedbackTrend
}

enum FeedbackTrend: String, CaseIterable {
    case increasing = "increasing"
    case stable = "stable"
    case decreasing = "decreasing"
    
    var displayName: String {
        switch self {
        case .increasing: return "Increasing"
        case .stable: return "Stable"
        case .decreasing: return "Decreasing"
        }
    }
    
    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .stable: return "➡️"
        case .decreasing: return "📉"
        }
    }
}

struct FeedbackExport: Codable {
    let feedbackHistory: [UserFeedback]
    let analytics: FeedbackAnalytics
    let exportDate: Date
    let version: String
}

enum FeedbackError: Error, LocalizedError {
    case invalidFeedback
    case submissionFailed
    case networkError
    case storageError
    
    var errorDescription: String? {
        switch self {
        case .invalidFeedback:
            return "Invalid feedback data"
        case .submissionFailed:
            return "Failed to submit feedback"
        case .networkError:
            return "Network error occurred"
        case .storageError:
            return "Storage error occurred"
        }
    }
}

// MARK: - Feedback Extensions
extension UserFeedbackService {
    func submitQuickFeedback(type: FeedbackType, message: String, rating: Int? = nil) async throws {
        let feedback = UserFeedback(
            type: type,
            category: .other,
            message: message,
            rating: rating
        )
        
        try await submitFeedback(feedback)
    }
    
    func submitBugReport(message: String, systemInfo: SystemInfo? = nil) async throws {
        var feedback = UserFeedback(
            type: .bugReport,
            category: .other,
            message: message
        )
        
        feedback.systemInfo = systemInfo ?? getSystemInfo()
        
        try await submitFeedback(feedback)
    }
    
    func submitFeatureRequest(message: String, category: FeedbackCategory = .other) async throws {
        let feedback = UserFeedback(
            type: .featureRequest,
            category: category,
            message: message
        )
        
        try await submitFeedback(feedback)
    }
    
    func submitRating(rating: Int, message: String? = nil) async throws {
        let feedback = UserFeedback(
            type: .rating,
            category: .other,
            message: message ?? "User rating: \(rating) stars",
            rating: rating
        )
        
        try await submitFeedback(feedback)
    }
}
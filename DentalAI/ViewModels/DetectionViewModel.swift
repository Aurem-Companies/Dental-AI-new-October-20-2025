import Foundation
import UIKit
import SwiftUI
import Combine

// MARK: - Detection View Model
class DetectionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var lastAnalysisResult: DentalAnalysisResult?
    @Published var analysisHistory: [DentalAnalysisResult] = []
    @Published var errorMessage: String?
    @Published var healthTrend: HealthTrend = .stable
    
    // MARK: - Private Properties
    private let dentalAnalysisEngine = DentalAnalysisEngine()
    private let dataManager = DataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadAnalysisHistory()
        updateHealthTrend()
    }
    
    // MARK: - Analysis Methods
    func analyzeImage(_ image: UIImage) async throws -> DentalAnalysisResult {
        await MainActor.run {
            isAnalyzing = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isAnalyzing = false
            }
        }
        
        do {
            let userProfile = dataManager.userProfile
            let result = try await dentalAnalysisEngine.analyzeDentalImage(image, userProfile: userProfile)
            
            await MainActor.run {
                lastAnalysisResult = result
                addAnalysisResult(result)
                updateHealthTrend()
            }
            
            return result
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - History Management
    private func loadAnalysisHistory() {
        analysisHistory = dataManager.analysisHistory
    }
    
    private func addAnalysisResult(_ result: DentalAnalysisResult) {
        analysisHistory.insert(result, at: 0) // Add to beginning (most recent first)
        
        // Keep only last 100 results
        if analysisHistory.count > 100 {
            analysisHistory = Array(analysisHistory.prefix(100))
        }
        
        // Save to data manager
        dataManager.addAnalysisResult(result)
    }
    
    func deleteAnalysisResult(_ result: DentalAnalysisResult) {
        analysisHistory.removeAll { $0.id == result.id }
        dataManager.deleteAnalysisResult(result)
        updateHealthTrend()
    }
    
    func clearAnalysisHistory() {
        analysisHistory.removeAll()
        dataManager.clearAnalysisHistory()
        updateHealthTrend()
    }
    
    // MARK: - Health Trend Analysis
    private func updateHealthTrend() {
        guard analysisHistory.count >= 2 else {
            healthTrend = .stable
            return
        }
        
        let recentResults = Array(analysisHistory.prefix(5))
        let olderResults = Array(analysisHistory.suffix(5))
        
        let recentAvg = recentResults.map { $0.healthScore }.reduce(0, +) / recentResults.count
        let olderAvg = olderResults.map { $0.healthScore }.reduce(0, +) / olderResults.count
        
        let improvementRate = (recentAvg - olderAvg) / Float(olderAvg)
        
        if improvementRate > 0.1 {
            healthTrend = .improving
        } else if improvementRate < -0.1 {
            healthTrend = .declining
        } else {
            healthTrend = .stable
        }
    }
    
    // MARK: - Statistics
    var averageHealthScore: Double {
        guard !analysisHistory.isEmpty else { return 0.0 }
        let total = analysisHistory.map { $0.healthScore }.reduce(0, +)
        return Double(total) / Double(analysisHistory.count)
    }
    
    var totalAnalyses: Int {
        return analysisHistory.count
    }
    
    var lastAnalysisDate: Date? {
        return analysisHistory.first?.timestamp
    }
    
    var healthScoreRange: ClosedRange<Int> {
        guard !analysisHistory.isEmpty else { return 0...100 }
        let scores = analysisHistory.map { $0.healthScore }
        return scores.min()!...scores.max()!
    }
    
    // MARK: - Condition Statistics
    func getConditionStatistics() -> [DentalCondition: ConditionStats] {
        var stats: [DentalCondition: ConditionStats] = [:]
        
        for result in analysisHistory {
            for (condition, confidence) in result.detectedConditions {
                if confidence > 0.5 {
                    if stats[condition] == nil {
                        stats[condition] = ConditionStats(
                            condition: condition,
                            count: 0,
                            averageConfidence: 0.0,
                            lastDetected: nil
                        )
                    }
                    
                    stats[condition]?.count += 1
                    stats[condition]?.averageConfidence = (stats[condition]?.averageConfidence ?? 0.0 + confidence) / 2.0
                    stats[condition]?.lastDetected = result.timestamp
                }
            }
        }
        
        return stats
    }
    
    // MARK: - Time-based Analysis
    func getHealthScoreTrend(days: Int = 30) -> [HealthScoreDataPoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentResults = analysisHistory.filter { $0.timestamp >= cutoffDate }
        
        return recentResults.map { result in
            HealthScoreDataPoint(
                date: result.timestamp,
                score: result.healthScore,
                confidence: result.confidence
            )
        }.sorted { $0.date < $1.date }
    }
    
    func getWeeklyAverage() -> Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weeklyResults = analysisHistory.filter { $0.timestamp >= weekAgo }
        
        guard !weeklyResults.isEmpty else { return 0.0 }
        
        let total = weeklyResults.map { $0.healthScore }.reduce(0, +)
        return Double(total) / Double(weeklyResults.count)
    }
    
    func getMonthlyAverage() -> Double {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlyResults = analysisHistory.filter { $0.timestamp >= monthAgo }
        
        guard !monthlyResults.isEmpty else { return 0.0 }
        
        let total = monthlyResults.map { $0.healthScore }.reduce(0, +)
        return Double(total) / Double(monthlyResults.count)
    }
    
    // MARK: - Recommendations
    func getPersonalizedRecommendations() -> [Recommendation] {
        guard let lastResult = lastAnalysisResult else { return [] }
        return lastResult.recommendations
    }
    
    func getRecommendationsByCategory(_ category: RecommendationCategory) -> [Recommendation] {
        return getPersonalizedRecommendations().filter { $0.category == category }
    }
    
    func getRecommendationsByPriority(_ priority: Priority) -> [Recommendation] {
        return getPersonalizedRecommendations().filter { $0.priority == priority }
    }
    
    // MARK: - Export/Import
    func exportAnalysisHistory() -> Data? {
        return dataManager.exportUserData()
    }
    
    func importAnalysisHistory(from data: Data) -> Bool {
        let success = dataManager.importUserData(from: data)
        if success {
            loadAnalysisHistory()
            updateHealthTrend()
        }
        return success
    }
    
    // MARK: - Validation
    func validateImage(_ image: UIImage) -> ValidationResult {
        let validationService = ValidationService()
        return validationService.validateImage(image)
    }
    
    func getRealTimeValidation(_ image: UIImage) -> RealTimeValidationResult {
        let validationService = ValidationService()
        return validationService.validateImageInRealTime(image)
    }
    
    // MARK: - Performance Monitoring
    func getPerformanceMetrics() -> PerformanceMetrics {
        guard !analysisHistory.isEmpty else {
            return PerformanceMetrics(
                averageAnalysisTime: 0.0,
                totalAnalyses: 0,
                successRate: 0.0,
                averageConfidence: 0.0
            )
        }
        
        let totalTime = analysisHistory.map { $0.analysisDuration }.reduce(0, +)
        let averageTime = totalTime / Double(analysisHistory.count)
        
        let successfulAnalyses = analysisHistory.filter { $0.confidence > 0.5 }.count
        let successRate = Double(successfulAnalyses) / Double(analysisHistory.count)
        
        let totalConfidence = analysisHistory.map { $0.confidence }.reduce(0, +)
        let averageConfidence = totalConfidence / Double(analysisHistory.count)
        
        return PerformanceMetrics(
            averageAnalysisTime: averageTime,
            totalAnalyses: analysisHistory.count,
            successRate: successRate,
            averageConfidence: averageConfidence
        )
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
    
    // MARK: - Data Refresh
    func refreshData() {
        loadAnalysisHistory()
        updateHealthTrend()
    }
    
    // MARK: - Search and Filter
    func searchAnalysisHistory(query: String) -> [DentalAnalysisResult] {
        guard !query.isEmpty else { return analysisHistory }
        
        return analysisHistory.filter { result in
            // Search in detected conditions
            let conditionMatches = result.detectedConditions.keys.contains { condition in
                condition.displayName.lowercased().contains(query.lowercased())
            }
            
            // Search in recommendations
            let recommendationMatches = result.recommendations.contains { recommendation in
                recommendation.personalizedText.lowercased().contains(query.lowercased()) ||
                recommendation.category.displayName.lowercased().contains(query.lowercased())
            }
            
            return conditionMatches || recommendationMatches
        }
    }
    
    func filterAnalysisHistory(by condition: DentalCondition) -> [DentalAnalysisResult] {
        return analysisHistory.filter { result in
            result.detectedConditions.keys.contains(condition)
        }
    }
    
    func filterAnalysisHistory(by dateRange: DateInterval) -> [DentalAnalysisResult] {
        return analysisHistory.filter { result in
            dateRange.contains(result.timestamp)
        }
    }
    
    func filterAnalysisHistory(by healthScoreRange: ClosedRange<Int>) -> [DentalAnalysisResult] {
        return analysisHistory.filter { result in
            healthScoreRange.contains(result.healthScore)
        }
    }
}

// MARK: - Supporting Types
struct ConditionStats {
    let condition: DentalCondition
    var count: Int
    var averageConfidence: Double
    var lastDetected: Date?
}

struct HealthScoreDataPoint {
    let date: Date
    let score: Int
    let confidence: Double
}

struct PerformanceMetrics {
    let averageAnalysisTime: Double
    let totalAnalyses: Int
    let successRate: Double
    let averageConfidence: Double
}

// MARK: - Extensions
extension DetectionViewModel {
    func getHealthScoreColor(for score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    func getHealthScoreEmoji(for score: Int) -> String {
        switch score {
        case 80...100: return "🦷"
        case 60..<80: return "⚠️"
        case 40..<60: return "⚡"
        default: return "🚨"
        }
    }
    
    func getHealthScoreDescription(for score: Int) -> String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Poor"
        default: return "Critical"
        }
    }
}

// MARK: - Combine Extensions
extension DetectionViewModel {
    func observeAnalysisHistory() -> AnyPublisher<[DentalAnalysisResult], Never> {
        return $analysisHistory
            .eraseToAnyPublisher()
    }
    
    func observeLastAnalysisResult() -> AnyPublisher<DentalAnalysisResult?, Never> {
        return $lastAnalysisResult
            .eraseToAnyPublisher()
    }
    
    func observeHealthTrend() -> AnyPublisher<HealthTrend, Never> {
        return $healthTrend
            .eraseToAnyPublisher()
    }
}
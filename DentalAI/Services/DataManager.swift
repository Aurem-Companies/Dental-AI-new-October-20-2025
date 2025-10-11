import Foundation
import SwiftUI

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var userProfile: UserProfile
    @Published var analysisHistory: [DentalAnalysisResult] = []
    
    private let userDefaults = UserDefaults.standard
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    // MARK: - Keys
    private enum Keys {
        static let userProfile = "userProfile"
        static let analysisHistory = "analysisHistory"
    }
    
    private init() {
        // Load user profile
        if let data = userDefaults.data(forKey: Keys.userProfile),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = profile
        } else {
            self.userProfile = UserProfile(
                name: "User",
                age: 30,
                dentalHistory: [],
                preferences: UserPreferences()
            )
        }
        
        // Load analysis history
        loadAnalysisHistory()
    }
    
    // MARK: - User Profile Management
    func updateUserProfile(_ profile: UserProfile) {
        userProfile = profile
        saveUserProfile()
    }
    
    func updateUserName(_ name: String) {
        userProfile.name = name
        saveUserProfile()
    }
    
    func updateUserAge(_ age: Int) {
        userProfile.age = age
        saveUserProfile()
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) {
        userProfile.preferences = preferences
        saveUserProfile()
    }
    
    // MARK: - Analysis History Management
    func addAnalysisResult(_ result: DentalAnalysisResult) {
        analysisHistory.append(result)
        userProfile.dentalHistory.append(result)
        
        // Keep only last 50 results to manage storage
        if analysisHistory.count > 50 {
            analysisHistory.removeFirst(analysisHistory.count - 50)
        }
        if userProfile.dentalHistory.count > 50 {
            userProfile.dentalHistory.removeFirst(userProfile.dentalHistory.count - 50)
        }
        
        saveAnalysisHistory()
        saveUserProfile()
    }
    
    func saveAnalysisResult(_ result: DentalAnalysisResult) async throws {
        addAnalysisResult(result)
    }
    
    func removeAnalysisResult(_ result: DentalAnalysisResult) {
        analysisHistory.removeAll { $0.id == result.id }
        userProfile.dentalHistory.removeAll { $0.id == result.id }
        
        saveAnalysisHistory()
        saveUserProfile()
    }
    
    func clearAnalysisHistory() {
        analysisHistory.removeAll()
        userProfile.dentalHistory.removeAll()
        
        saveAnalysisHistory()
        saveUserProfile()
    }
    
    // MARK: - Data Persistence
    private func saveUserProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(data, forKey: Keys.userProfile)
        }
    }
    
    private func saveAnalysisHistory() {
        if let data = try? JSONEncoder().encode(analysisHistory) {
            userDefaults.set(data, forKey: Keys.analysisHistory)
        }
    }
    
    private func loadAnalysisHistory() {
        if let data = userDefaults.data(forKey: Keys.analysisHistory),
           let history = try? JSONDecoder().decode([DentalAnalysisResult].self, from: data) {
            self.analysisHistory = history
        }
    }
    
    // MARK: - Image Storage
    func saveImage(_ image: UIImage, for result: DentalAnalysisResult) -> String? {
        let imageName = "\(result.id.uuidString).jpg"
        let imageURL = documentsDirectory.appendingPathComponent(imageName)
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return nil
        }
        
        do {
            try imageData.write(to: imageURL)
            return imageName
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(for result: DentalAnalysisResult) -> UIImage? {
        let imageName = "\(result.id.uuidString).jpg"
        let imageURL = documentsDirectory.appendingPathComponent(imageName)
        
        guard let imageData = try? Data(contentsOf: imageURL) else {
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    func deleteImage(for result: DentalAnalysisResult) {
        let imageName = "\(result.id.uuidString).jpg"
        let imageURL = documentsDirectory.appendingPathComponent(imageName)
        
        try? FileManager.default.removeItem(at: imageURL)
    }
    
    // MARK: - Data Export
    func exportUserData() -> Data? {
        let exportData = UserDataExport(
            userProfile: userProfile,
            analysisHistory: analysisHistory,
            exportDate: Date()
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importUserData(_ data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(UserDataExport.self, from: data) else {
            return false
        }
        
        userProfile = importData.userProfile
        analysisHistory = importData.analysisHistory
        
        saveUserProfile()
        saveAnalysisHistory()
        
        return true
    }
    
    // MARK: - Statistics
    func getHealthStatistics() -> HealthStatistics {
        let totalAnalyses = analysisHistory.count
        let averageScore = analysisHistory.isEmpty ? 0 : analysisHistory.map { $0.overallHealthScore }.reduce(0, +) / totalAnalyses
        
        let conditionCounts = Dictionary(grouping: analysisHistory.flatMap { $0.conditions }, by: { $0 })
            .mapValues { $0.count }
        
        let severityCounts = Dictionary(grouping: analysisHistory.map { $0.severity }, by: { $0 })
            .mapValues { $0.count }
        
        let recentTrend = calculateRecentTrend()
        
        return HealthStatistics(
            totalAnalyses: totalAnalyses,
            averageHealthScore: averageScore,
            conditionCounts: conditionCounts,
            severityCounts: severityCounts,
            recentTrend: recentTrend,
            lastAnalysisDate: analysisHistory.last?.timestamp
        )
    }
    
    private func calculateRecentTrend() -> HealthTrend {
        guard analysisHistory.count >= 3 else { return .stable }
        
        let recent = analysisHistory.suffix(3)
        let scores = recent.map { $0.overallHealthScore }
        
        if scores.isIncreasing {
            return .improving
        } else if scores.isDecreasing {
            return .declining
        } else {
            return .stable
        }
    }
    
    // MARK: - Backup and Restore
    func createBackup() -> URL? {
        let backupData = exportUserData()
        guard let data = backupData else { return nil }
        
        let backupURL = documentsDirectory.appendingPathComponent("DentalAI_Backup_\(Date().timeIntervalSince1970).json")
        
        do {
            try data.write(to: backupURL)
            return backupURL
        } catch {
            print("Error creating backup: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(_ url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            return importUserData(data)
        } catch {
            print("Error restoring backup: \(error)")
            return false
        }
    }
    
    // MARK: - Privacy and Security
    func clearAllData() {
        // Clear user defaults
        userDefaults.removeObject(forKey: Keys.userProfile)
        userDefaults.removeObject(forKey: Keys.analysisHistory)
        
        // Clear images
        let fileManager = FileManager.default
        do {
            let imageFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "jpg" }
            
            for file in imageFiles {
                try fileManager.removeItem(at: file)
            }
        } catch {
            print("Error clearing images: \(error)")
        }
        
        // Reset to default
        userProfile = UserProfile(
            name: "User",
            age: 30,
            dentalHistory: [],
            preferences: UserPreferences()
        )
        analysisHistory = []
    }
    
    // MARK: - Data Validation
    func validateData() -> [String] {
        var issues: [String] = []
        
        // Check for orphaned images
        let imageFiles = (try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "jpg" }) ?? []
        
        let expectedImageNames = Set(analysisHistory.map { "\($0.id.uuidString).jpg" })
        let actualImageNames = Set(imageFiles.map { $0.lastPathComponent })
        
        let orphanedImages = actualImageNames.subtracting(expectedImageNames)
        if !orphanedImages.isEmpty {
            issues.append("Found \(orphanedImages.count) orphaned image files")
        }
        
        // Check for missing images
        let missingImages = expectedImageNames.subtracting(actualImageNames)
        if !missingImages.isEmpty {
            issues.append("Missing images for \(missingImages.count) analysis results")
        }
        
        // Check for invalid data
        if userProfile.name.isEmpty {
            issues.append("User name is empty")
        }
        
        if userProfile.age < 0 || userProfile.age > 150 {
            issues.append("Invalid user age: \(userProfile.age)")
        }
        
        return issues
    }
    
    func repairData() {
        // Remove orphaned images
        let imageFiles = (try? FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "jpg" }) ?? []
        
        let expectedImageNames = Set(analysisHistory.map { "\($0.id.uuidString).jpg" })
        
        for file in imageFiles {
            if !expectedImageNames.contains(file.lastPathComponent) {
                try? FileManager.default.removeItem(at: file)
            }
        }
        
        // Fix invalid user data
        if userProfile.name.isEmpty {
            userProfile.name = "User"
        }
        
        if userProfile.age < 0 || userProfile.age > 150 {
            userProfile.age = 30
        }
        
        saveUserProfile()
    }
}

// MARK: - Supporting Types
struct UserDataExport: Codable {
    let userProfile: UserProfile
    let analysisHistory: [DentalAnalysisResult]
    let exportDate: Date
}

struct HealthStatistics {
    let totalAnalyses: Int
    let averageHealthScore: Int
    let conditionCounts: [DentalCondition: Int]
    let severityCounts: [SeverityLevel: Int]
    let recentTrend: HealthTrend
    let lastAnalysisDate: Date?
}

// MARK: - Extensions for Codable
extension DentalCondition: Codable {}
extension SeverityLevel: Codable {}
extension Recommendation: Codable {}
extension Recommendation.Priority: Codable {}
extension Recommendation.RecommendationCategory: Codable {}
extension UserProfile: Codable {}
extension UserPreferences: Codable {}
extension ReminderFrequency: Codable {}
extension HealthTrend: Codable {}
extension DentalAnalysisResult: Codable {}

// MARK: - Extensions for Array
extension Array where Element == Int {
    var isIncreasing: Bool {
        guard count >= 2 else { return false }
        for i in 1..<count {
            if self[i] <= self[i-1] { return false }
        }
        return true
    }
    
    var isDecreasing: Bool {
        guard count >= 2 else { return false }
        for i in 1..<count {
            if self[i] >= self[i-1] { return false }
        }
        return true
    }
}

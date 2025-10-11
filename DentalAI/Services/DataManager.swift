import Foundation
import UIKit
import Security
import CryptoKit

// MARK: - Data Manager
class DataManager: ObservableObject {
    
    // MARK: - Properties
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults.standard
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let imagesDirectory: URL
    private let backupDirectory: URL
    
    // Keys for UserDefaults
    private enum Keys {
        static let userProfile = "userProfile"
        static let analysisHistory = "analysisHistory"
        static let settings = "settings"
        static let lastBackup = "lastBackup"
        static let dataVersion = "dataVersion"
    }
    
    // MARK: - Initialization
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        imagesDirectory = documentsDirectory.appendingPathComponent("DentalImages")
        backupDirectory = documentsDirectory.appendingPathComponent("Backups")
        
        createDirectoriesIfNeeded()
        migrateDataIfNeeded()
    }
    
    // MARK: - Directory Setup
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - User Profile Management
    var userProfile: UserProfile {
        get {
            if let data = userDefaults.data(forKey: Keys.userProfile),
               let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
            return UserProfile()
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: Keys.userProfile)
            }
        }
    }
    
    func saveUserProfile(_ profile: UserProfile) {
        userProfile = profile
    }
    
    func updateUserProfile(age: Int? = nil, preferences: [String]? = nil, remindersEnabled: Bool? = nil) {
        var profile = userProfile
        
        if let age = age {
            profile.age = age
        }
        
        if let preferences = preferences {
            profile.preferences = preferences
        }
        
        if let remindersEnabled = remindersEnabled {
            profile.remindersEnabled = remindersEnabled
        }
        
        profile.updateLastUpdated()
        saveUserProfile(profile)
    }
    
    // MARK: - Analysis History Management
    var analysisHistory: [DentalAnalysisResult] {
        get {
            if let data = userDefaults.data(forKey: Keys.analysisHistory),
               let history = try? JSONDecoder().decode([DentalAnalysisResult].self, from: data) {
                return history.sorted { $0.timestamp > $1.timestamp }
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                userDefaults.set(data, forKey: Keys.analysisHistory)
            }
        }
    }
    
    func addAnalysisResult(_ result: DentalAnalysisResult) {
        var history = analysisHistory
        history.insert(result, at: 0) // Add to beginning (most recent first)
        
        // Keep only last 100 results to prevent storage bloat
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        analysisHistory = history
        
        // Update user profile
        var profile = userProfile
        profile.analysisHistory = history
        saveUserProfile(profile)
    }
    
    func saveAnalysisResult(_ result: DentalAnalysisResult) {
        addAnalysisResult(result)
    }
    
    func deleteAnalysisResult(_ result: DentalAnalysisResult) {
        var history = analysisHistory
        history.removeAll { $0.id == result.id }
        analysisHistory = history
        
        // Delete associated image file
        if let imageURL = result.imageURL {
            try? fileManager.removeItem(at: imageURL)
        }
    }
    
    func clearAnalysisHistory() {
        analysisHistory = []
        
        // Clear image directory
        try? fileManager.removeItem(at: imagesDirectory)
        createDirectoriesIfNeeded()
    }
    
    // MARK: - Image Management
    func saveImage(_ image: UIImage, withName name: String) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let imageURL = imagesDirectory.appendingPathComponent("\(name).jpg")
        
        do {
            try imageData.write(to: imageURL)
            return imageURL
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func loadImage(from url: URL) -> UIImage? {
        return UIImage(contentsOfFile: url.path)
    }
    
    func deleteImage(at url: URL) {
        try? fileManager.removeItem(at: url)
    }
    
    func getImageSize(at url: URL) -> Int64 {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - Data Export/Import
    func exportUserData() -> Data? {
        let exportData = UserDataExport(
            userProfile: userProfile,
            analysisHistory: analysisHistory,
            exportDate: Date(),
            version: "1.0"
        )
        
        return try? JSONEncoder().encode(exportData)
    }
    
    func importUserData(from data: Data) -> Bool {
        guard let importData = try? JSONDecoder().decode(UserDataExport.self, from: data) else {
            return false
        }
        
        // Validate imported data
        let validator = ValidationService()
        let profileValidation = validator.validateUserProfile(importData.userProfile)
        
        if !profileValidation.isValid {
            return false
        }
        
        // Import data
        userProfile = importData.userProfile
        analysisHistory = importData.analysisHistory
        
        return true
    }
    
    // MARK: - Backup Management
    func createBackup() -> URL? {
        guard let exportData = exportUserData() else { return nil }
        
        let timestamp = DateFormatter.backupFormatter.string(from: Date())
        let backupURL = backupDirectory.appendingPathComponent("DentalAI_Backup_\(timestamp).json")
        
        do {
            try exportData.write(to: backupURL)
            userDefaults.set(Date(), forKey: Keys.lastBackup)
            return backupURL
        } catch {
            print("Failed to create backup: \(error)")
            return nil
        }
    }
    
    func restoreFromBackup(at url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            return importUserData(from: data)
        } catch {
            print("Failed to restore from backup: \(error)")
            return false
        }
    }
    
    func getAvailableBackups() -> [URL] {
        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
            return backupFiles.filter { $0.pathExtension == "json" }
                .sorted { $0.creationDate ?? Date.distantPast > $1.creationDate ?? Date.distantPast }
        } catch {
            return []
        }
    }
    
    // MARK: - Health Statistics
    func getHealthStatistics() -> HealthStatistics {
        let history = analysisHistory
        
        guard !history.isEmpty else {
            return HealthStatistics()
        }
        
        let scores = history.map { Double($0.healthScore) }
        let avgScore = scores.reduce(0, +) / Double(scores.count)
        
        // Calculate trends (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentHistory = history.filter { $0.timestamp >= thirtyDaysAgo }
        
        let recentScores = recentHistory.map { Double($0.healthScore) }
        let recentAvgScore = recentScores.isEmpty ? avgScore : recentScores.reduce(0, +) / Double(recentScores.count)
        
        let improvementRate = recentAvgScore - avgScore
        
        // Calculate risk factors
        var riskFactors: [DentalCondition: Int] = [:]
        for result in history {
            for (condition, confidence) in result.detectedConditions {
                if confidence > 0.7 {
                    riskFactors[condition, default: 0] += 1
                }
            }
        }
        
        // Calculate seasonal trends
        var seasonalTrends: [String: Double] = [:]
        let calendar = Calendar.current
        for result in history {
            let month = calendar.component(.month, from: result.timestamp)
            let season = getSeason(for: month)
            seasonalTrends[season, default: 0] += Double(result.healthScore)
        }
        
        // Normalize seasonal trends
        for key in seasonalTrends.keys {
            let count = history.filter { result in
                let month = calendar.component(.month, from: result.timestamp)
                return getSeason(for: month) == key
            }.count
            if count > 0 {
                seasonalTrends[key] = seasonalTrends[key]! / Double(count)
            }
        }
        
        return HealthStatistics(
            avgScore: avgScore,
            trends: ["30_day_avg": recentAvgScore],
            lastAnalysisDate: history.first?.timestamp,
            totalAnalyses: history.count,
            improvementRate: improvementRate,
            riskFactors: riskFactors,
            seasonalTrends: seasonalTrends
        )
    }
    
    private func getSeason(for month: Int) -> String {
        switch month {
        case 12, 1, 2: return "Winter"
        case 3, 4, 5: return "Spring"
        case 6, 7, 8: return "Summer"
        case 9, 10, 11: return "Fall"
        default: return "Unknown"
        }
    }
    
    // MARK: - Data Validation and Repair
    func validateData() -> DataValidationResult {
        var issues: [String] = []
        var repaired: [String] = []
        
        // Validate user profile
        let validator = ValidationService()
        let profileValidation = validator.validateUserProfile(userProfile)
        
        if !profileValidation.isValid {
            issues.append("User profile validation failed")
            // Repair by creating default profile
            if userProfile.age == nil && userProfile.preferences.isEmpty {
                userProfile = UserProfile()
                repaired.append("Created default user profile")
            }
        }
        
        // Validate analysis history
        var validHistory: [DentalAnalysisResult] = []
        for result in analysisHistory {
            let resultValidation = validator.validateAnalysisResult(result)
            if resultValidation.isValid {
                validHistory.append(result)
            } else {
                issues.append("Invalid analysis result: \(result.id)")
            }
        }
        
        if validHistory.count != analysisHistory.count {
            analysisHistory = validHistory
            repaired.append("Removed \(analysisHistory.count - validHistory.count) invalid analysis results")
        }
        
        // Check for orphaned image files
        let imageFiles = try? fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: nil)
        let referencedImages = Set(analysisHistory.compactMap { $0.imageURL })
        
        if let imageFiles = imageFiles {
            for imageFile in imageFiles {
                if !referencedImages.contains(imageFile) {
                    try? fileManager.removeItem(at: imageFile)
                    repaired.append("Removed orphaned image: \(imageFile.lastPathComponent)")
                }
            }
        }
        
        return DataValidationResult(
            hasIssues: !issues.isEmpty,
            issues: issues,
            repaired: repaired,
            isValid: issues.isEmpty
        )
    }
    
    func repairData() -> Bool {
        let validation = validateData()
        return validation.isValid
    }
    
    // MARK: - Storage Management
    func getStorageInfo() -> StorageInfo {
        let imageFiles = try? fileManager.contentsOfDirectory(at: imagesDirectory, includingPropertiesForKeys: [.fileSizeKey])
        let backupFiles = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.fileSizeKey])
        
        let imageSize = imageFiles?.reduce(0) { total, url in
            total + (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0
        } ?? 0
        
        let backupSize = backupFiles?.reduce(0) { total, url in
            total + (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) ?? 0
        } ?? 0
        
        let totalSize = imageSize + backupSize
        
        return StorageInfo(
            totalSize: totalSize,
            imageSize: imageSize,
            backupSize: backupSize,
            imageCount: imageFiles?.count ?? 0,
            backupCount: backupFiles?.count ?? 0
        )
    }
    
    func clearOldData(olderThan days: Int = 90) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Remove old analysis results
        var history = analysisHistory
        let oldResults = history.filter { $0.timestamp < cutoffDate }
        
        for result in oldResults {
            if let imageURL = result.imageURL {
                try? fileManager.removeItem(at: imageURL)
            }
        }
        
        history.removeAll { $0.timestamp < cutoffDate }
        analysisHistory = history
        
        // Remove old backups
        let backupFiles = try? fileManager.contentsOfDirectory(at: backupDirectory, includingPropertiesForKeys: [.creationDateKey])
        for backupFile in backupFiles ?? [] {
            if let creationDate = try? backupFile.resourceValues(forKeys: [.creationDateKey]).creationDate,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: backupFile)
            }
        }
    }
    
    // MARK: - Data Migration
    private func migrateDataIfNeeded() {
        let currentVersion = "1.0"
        let storedVersion = userDefaults.string(forKey: Keys.dataVersion) ?? "0.0"
        
        if storedVersion != currentVersion {
            performDataMigration(from: storedVersion, to: currentVersion)
            userDefaults.set(currentVersion, forKey: Keys.dataVersion)
        }
    }
    
    private func performDataMigration(from oldVersion: String, to newVersion: String) {
        // Handle data migration between versions
        print("Migrating data from \(oldVersion) to \(newVersion)")
        
        // Add migration logic here as needed
        // For now, just update the version
    }
    
    // MARK: - Privacy and Security
    func clearAllData() {
        // Clear UserDefaults
        userDefaults.removeObject(forKey: Keys.userProfile)
        userDefaults.removeObject(forKey: Keys.analysisHistory)
        userDefaults.removeObject(forKey: Keys.settings)
        userDefaults.removeObject(forKey: Keys.lastBackup)
        userDefaults.removeObject(forKey: Keys.dataVersion)
        
        // Clear file system
        try? fileManager.removeItem(at: imagesDirectory)
        try? fileManager.removeItem(at: backupDirectory)
        
        // Recreate directories
        createDirectoriesIfNeeded()
        
        // Reset to default profile
        userProfile = UserProfile()
    }
    
    func encryptSensitiveData(_ data: Data) -> Data? {
        // Use CryptoKit for encryption
        let key = SymmetricKey(size: .bits256)
        return try? AES.GCM.seal(data, using: key).combined
    }
    
    func decryptSensitiveData(_ encryptedData: Data) -> Data? {
        // Use CryptoKit for decryption
        let key = SymmetricKey(size: .bits256)
        guard let sealedBox = try? AES.GCM.SealedBox(combined: encryptedData) else { return nil }
        return try? AES.GCM.open(sealedBox, using: key)
    }
}

// MARK: - Supporting Types
struct UserDataExport: Codable {
    let userProfile: UserProfile
    let analysisHistory: [DentalAnalysisResult]
    let exportDate: Date
    let version: String
}

struct DataValidationResult {
    let hasIssues: Bool
    let issues: [String]
    let repaired: [String]
    let isValid: Bool
}

struct StorageInfo {
    let totalSize: Int64
    let imageSize: Int64
    let backupSize: Int64
    let imageCount: Int
    let backupCount: Int
    
    var totalSizeMB: Double {
        return Double(totalSize) / (1024 * 1024)
    }
    
    var imageSizeMB: Double {
        return Double(imageSize) / (1024 * 1024)
    }
    
    var backupSizeMB: Double {
        return Double(backupSize) / (1024 * 1024)
    }
}

// MARK: - Extensions
extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}

extension URL {
    var creationDate: Date? {
        return try? resourceValues(forKeys: [.creationDateKey]).creationDate
    }
}
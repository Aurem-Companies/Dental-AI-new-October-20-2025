import XCTest
import UIKit
@testable import DentalAI

final class DentalAITests: XCTestCase {
    
    var analysisEngine: DentalAnalysisEngine!
    var imageProcessor: MockImageProcessor!
    var dataManager: DataManager!
    
    override func setUpWithError() throws {
        // Initialize test dependencies
        imageProcessor = MockImageProcessor()
        analysisEngine = DentalAnalysisEngine(imageProcessor: imageProcessor)
        dataManager = DataManager.shared
    }
    
    override func tearDownWithError() throws {
        analysisEngine = nil
        imageProcessor = nil
        dataManager = nil
    }
    
    // MARK: - Image Processing Tests
    func testImageEnhancement() async throws {
        // Given
        let testImage = createTestImage()
        imageProcessor.mockEnhancedImage = testImage
        
        // When
        let result = try await imageProcessor.enhanceImage(testImage)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(imageProcessor.enhanceImageCallCount, 1)
    }
    
    func testImageQualityAssessment() {
        // Given
        let testImage = createTestImage()
        let expectedQuality = ImageQuality(poor: false, issues: [])
        imageProcessor.mockImageQuality = expectedQuality
        
        // When
        let quality = imageProcessor.assessImageQuality(testImage)
        
        // Then
        XCTAssertEqual(quality.poor, false)
        XCTAssertEqual(quality.issues.count, 0)
        XCTAssertEqual(imageProcessor.assessImageQualityCallCount, 1)
    }
    
    func testToothColorAnalysis() async throws {
        // Given
        let testImage = createTestImage()
        let expectedAnalysis = ToothColorAnalysis(dominantColor: .white, healthiness: 0.9)
        imageProcessor.mockToothColorAnalysis = expectedAnalysis
        
        // When
        let result = try await imageProcessor.analyzeToothColor(testImage)
        
        // Then
        XCTAssertEqual(result.dominantColor, .white)
        XCTAssertEqual(result.healthiness, 0.9, accuracy: 0.1)
        XCTAssertEqual(imageProcessor.analyzeToothColorCallCount, 1)
    }
    
    // MARK: - Analysis Engine Tests
    func testDentalAnalysisSuccess() async {
        // Given
        let testImage = createTestImage()
        let expectedResult = createMockAnalysisResult()
        imageProcessor.mockImageQuality = ImageQuality(poor: false, issues: [])
        imageProcessor.mockEnhancedImage = testImage
        imageProcessor.mockToothColorAnalysis = ToothColorAnalysis(dominantColor: .white, healthiness: 0.9)
        
        // When
        let result = await analysisEngine.analyzeDentalImage(testImage)
        
        // Then
        switch result {
        case .success(let analysisResult):
            XCTAssertNotNil(analysisResult)
            XCTAssertGreaterThan(analysisResult.confidence, 0.0)
            XCTAssertFalse(analysisResult.conditions.isEmpty)
        case .failure(let error):
            XCTFail("Analysis should succeed, but failed with: \(error.localizedDescription)")
        }
    }
    
    func testDentalAnalysisWithInvalidImage() async {
        // Given
        let invalidImage = UIImage() // Empty image
        
        // When
        let result = await analysisEngine.analyzeDentalImage(invalidImage)
        
        // Then
        switch result {
        case .success:
            XCTFail("Analysis should fail with invalid image")
        case .failure(let error):
            XCTAssertEqual(error, AnalysisError.invalidImage)
        }
    }
    
    func testDentalAnalysisWithLowQualityImage() async {
        // Given
        let testImage = createTestImage()
        let lowQuality = ImageQuality(poor: true, issues: ["Image too dark", "Low resolution"])
        imageProcessor.mockImageQuality = lowQuality
        
        // When
        let result = await analysisEngine.analyzeDentalImage(testImage)
        
        // Then
        switch result {
        case .success:
            XCTFail("Analysis should fail with low quality image")
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Image too dark"))
            } else {
                XCTFail("Expected lowQualityImage error")
            }
        }
    }
    
    // MARK: - Data Manager Tests
    func testUserProfileUpdate() {
        // Given
        let newName = "Test User"
        let newAge = 25
        
        // When
        dataManager.updateUserName(newName)
        dataManager.updateUserAge(newAge)
        
        // Then
        XCTAssertEqual(dataManager.userProfile.name, newName)
        XCTAssertEqual(dataManager.userProfile.age, newAge)
    }
    
    func testAnalysisHistoryManagement() {
        // Given
        let mockResult = createMockAnalysisResult()
        
        // When
        dataManager.addAnalysisResult(mockResult)
        
        // Then
        XCTAssertEqual(dataManager.analysisHistory.count, 1)
        XCTAssertEqual(dataManager.userProfile.dentalHistory.count, 1)
        XCTAssertEqual(dataManager.analysisHistory.first?.id, mockResult.id)
    }
    
    func testDataExportImport() {
        // Given
        let mockResult = createMockAnalysisResult()
        dataManager.addAnalysisResult(mockResult)
        
        // When
        guard let exportData = dataManager.exportUserData() else {
            XCTFail("Export should succeed")
            return
        }
        
        // Clear data
        dataManager.clearAnalysisHistory()
        XCTAssertEqual(dataManager.analysisHistory.count, 0)
        
        // Import data
        let importSuccess = dataManager.importUserData(exportData)
        
        // Then
        XCTAssertTrue(importSuccess)
        XCTAssertEqual(dataManager.analysisHistory.count, 1)
        XCTAssertEqual(dataManager.analysisHistory.first?.id, mockResult.id)
    }
    
    // MARK: - Validation Tests
    func testImageValidation() {
        // Given
        let validationService = ValidationService()
        let testImage = createTestImage()
        
        // When
        let result = validationService.validateImage(testImage)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.severity, .none)
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    func testUserProfileValidation() {
        // Given
        let validationService = ValidationService()
        let validProfile = UserProfile(
            name: "Test User",
            age: 30,
            dentalHistory: [],
            preferences: UserPreferences()
        )
        
        // When
        let result = validationService.validateUserProfile(validProfile)
        
        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.severity, .none)
        XCTAssertTrue(result.issues.isEmpty)
    }
    
    func testInvalidUserProfileValidation() {
        // Given
        let validationService = ValidationService()
        let invalidProfile = UserProfile(
            name: "", // Empty name
            age: -1,  // Invalid age
            dentalHistory: [],
            preferences: UserPreferences()
        )
        
        // When
        let result = validationService.validateUserProfile(invalidProfile)
        
        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.severity, .error)
        XCTAssertFalse(result.issues.isEmpty)
    }
    
    // MARK: - Performance Tests
    func testAnalysisPerformance() async {
        // Given
        let testImage = createTestImage()
        imageProcessor.mockImageQuality = ImageQuality(poor: false, issues: [])
        imageProcessor.mockEnhancedImage = testImage
        imageProcessor.mockToothColorAnalysis = ToothColorAnalysis(dominantColor: .white, healthiness: 0.9)
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await analysisEngine.analyzeDentalImage(testImage)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        switch result {
        case .success:
            XCTAssertLessThan(timeElapsed, 5.0, "Analysis should complete within 5 seconds")
        case .failure:
            XCTFail("Performance test should succeed")
        }
    }
    
    // MARK: - Helper Methods
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createMockAnalysisResult() -> DentalAnalysisResult {
        return DentalAnalysisResult(
            conditions: [.healthy],
            confidence: 0.85,
            severity: .none,
            recommendations: [
                Recommendation(
                    title: "Maintain Good Oral Health",
                    description: "Keep up your excellent oral hygiene routine.",
                    priority: .general,
                    category: .homeCare,
                    actionItems: ["Continue regular brushing and flossing"]
                )
            ],
            timestamp: Date(),
            image: createTestImage()
        )
    }
}

// MARK: - Mock Classes
class MockImageProcessor: ImageProcessing {
    var mockEnhancedImage: UIImage?
    var mockImageQuality: ImageQuality?
    var mockToothColorAnalysis: ToothColorAnalysis?
    var mockEdgeImage: UIImage?
    
    var enhanceImageCallCount = 0
    var assessImageQualityCallCount = 0
    var analyzeToothColorCallCount = 0
    var detectEdgesCallCount = 0
    var cropToTeethRegionCallCount = 0
    
    func enhanceImage(_ image: UIImage) async throws -> UIImage {
        enhanceImageCallCount += 1
        return mockEnhancedImage ?? image
    }
    
    func assessImageQuality(_ image: UIImage) -> ImageQuality {
        assessImageQualityCallCount += 1
        return mockImageQuality ?? ImageQuality(poor: false, issues: [])
    }
    
    func analyzeToothColor(_ image: UIImage) async throws -> ToothColorAnalysis {
        analyzeToothColorCallCount += 1
        return mockToothColorAnalysis ?? ToothColorAnalysis(dominantColor: .white, healthiness: 0.9)
    }
    
    func detectEdges(_ image: UIImage) async throws -> UIImage? {
        detectEdgesCallCount += 1
        return mockEdgeImage
    }
    
    func cropToTeethRegion(_ image: UIImage) async throws -> UIImage? {
        cropToTeethRegionCallCount += 1
        return image
    }
}

import XCTest
import UIKit
@testable import DentalAI

// MARK: - Detection Tests
class DetectionTests: XCTestCase {
    
    var detectionViewModel: DetectionViewModel!
    var dentalAnalysisEngine: DentalAnalysisEngine!
    var imageProcessor: ImageProcessor!
    var validationService: ValidationService!
    
    override func setUpWithError() throws {
        detectionViewModel = DetectionViewModel()
        dentalAnalysisEngine = DentalAnalysisEngine()
        imageProcessor = ImageProcessor()
        validationService = ValidationService()
    }
    
    override func tearDownWithError() throws {
        detectionViewModel = nil
        dentalAnalysisEngine = nil
        imageProcessor = nil
        validationService = nil
    }
    
    // MARK: - Image Processing Tests
    func testImageEnhancement() throws {
        // Create a test image
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        // Test image enhancement
        let enhancedImage = imageProcessor.enhanceImage(testImage)
        
        XCTAssertNotNil(enhancedImage, "Enhanced image should not be nil")
        XCTAssertEqual(enhancedImage?.size, testImage.size, "Enhanced image should maintain original size")
    }
    
    func testImageResizing() throws {
        let testImage = createTestImage(size: CGSize(width: 500, height: 500))
        let targetSize = CGSize(width: 224, height: 224)
        
        let resizedImage = imageProcessor.resizeImage(testImage, to: targetSize)
        
        XCTAssertNotNil(resizedImage, "Resized image should not be nil")
        XCTAssertEqual(resizedImage?.size, targetSize, "Resized image should match target size")
    }
    
    func testImageQualityAssessment() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        let quality = imageProcessor.assessImageQuality(testImage)
        
        XCTAssertGreaterThanOrEqual(quality.overallScore, 0.0, "Overall score should be >= 0")
        XCTAssertLessThanOrEqual(quality.overallScore, 1.0, "Overall score should be <= 1")
        XCTAssertGreaterThanOrEqual(quality.sharpness, 0.0, "Sharpness should be >= 0")
        XCTAssertLessThanOrEqual(quality.sharpness, 1.0, "Sharpness should be <= 1")
        XCTAssertGreaterThanOrEqual(quality.brightness, 0.0, "Brightness should be >= 0")
        XCTAssertLessThanOrEqual(quality.brightness, 1.0, "Brightness should be <= 1")
        XCTAssertGreaterThanOrEqual(quality.contrast, 0.0, "Contrast should be >= 0")
        XCTAssertLessThanOrEqual(quality.contrast, 1.0, "Contrast should be <= 1")
        XCTAssertGreaterThanOrEqual(quality.blur, 0.0, "Blur should be >= 0")
        XCTAssertLessThanOrEqual(quality.blur, 1.0, "Blur should be <= 1")
    }
    
    func testToothColorAnalysis() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        let colorAnalysis = imageProcessor.analyzeToothColor(testImage)
        
        XCTAssertGreaterThanOrEqual(colorAnalysis.healthiness, 0.0, "Healthiness should be >= 0")
        XCTAssertLessThanOrEqual(colorAnalysis.healthiness, 1.0, "Healthiness should be <= 1")
        XCTAssertGreaterThanOrEqual(colorAnalysis.confidence, 0.0, "Confidence should be >= 0")
        XCTAssertLessThanOrEqual(colorAnalysis.confidence, 1.0, "Confidence should be <= 1")
    }
    
    func testEdgeDetection() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        let edgeAnalysis = imageProcessor.detectEdges(testImage)
        
        XCTAssertGreaterThanOrEqual(edgeAnalysis.edgeCount, 0, "Edge count should be >= 0")
        XCTAssertGreaterThanOrEqual(edgeAnalysis.edgeStrength, 0.0, "Edge strength should be >= 0")
        XCTAssertGreaterThanOrEqual(edgeAnalysis.confidence, 0.0, "Confidence should be >= 0")
        XCTAssertLessThanOrEqual(edgeAnalysis.confidence, 1.0, "Confidence should be <= 1")
    }
    
    // MARK: - Validation Tests
    func testImageValidation() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        let validation = validationService.validateImage(testImage)
        
        XCTAssertNotNil(validation, "Validation result should not be nil")
        XCTAssertNotNil(validation.isValid, "Validation should have isValid property")
    }
    
    func testImageValidationWithSmallImage() throws {
        let smallImage = createTestImage(size: CGSize(width: 100, height: 100))
        
        let validation = validationService.validateImage(smallImage)
        
        XCTAssertFalse(validation.isValid, "Small image should be invalid")
        XCTAssertTrue(validation.errors.contains(.imageTooSmall), "Should contain imageTooSmall error")
    }
    
    func testImageValidationWithLargeImage() throws {
        let largeImage = createTestImage(size: CGSize(width: 5000, height: 5000))
        
        let validation = validationService.validateImage(largeImage)
        
        XCTAssertFalse(validation.isValid, "Large image should be invalid")
        XCTAssertTrue(validation.errors.contains(.imageTooLarge), "Should contain imageTooLarge error")
    }
    
    func testUserProfileValidation() throws {
        let validProfile = UserProfile(age: 25, preferences: ["test"], analysisHistory: [])
        
        let validation = validationService.validateUserProfile(validProfile)
        
        XCTAssertTrue(validation.isValid, "Valid profile should pass validation")
        XCTAssertTrue(validation.errors.isEmpty, "Valid profile should have no errors")
    }
    
    func testUserProfileValidationWithInvalidAge() throws {
        let invalidProfile = UserProfile(age: -1, preferences: [], analysisHistory: [])
        
        let validation = validationService.validateUserProfile(invalidProfile)
        
        XCTAssertFalse(validation.isValid, "Invalid profile should fail validation")
        XCTAssertFalse(validation.errors.isEmpty, "Invalid profile should have errors")
    }
    
    func testAnalysisResultValidation() throws {
        let validResult = DentalAnalysisResult(
            healthScore: 75,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        let validation = validationService.validateAnalysisResult(validResult)
        
        XCTAssertTrue(validation.isValid, "Valid result should pass validation")
        XCTAssertTrue(validation.errors.isEmpty, "Valid result should have no errors")
    }
    
    func testAnalysisResultValidationWithInvalidScore() throws {
        let invalidResult = DentalAnalysisResult(
            healthScore: 150, // Invalid score
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        let validation = validationService.validateAnalysisResult(invalidResult)
        
        XCTAssertFalse(validation.isValid, "Invalid result should fail validation")
        XCTAssertFalse(validation.errors.isEmpty, "Invalid result should have errors")
    }
    
    // MARK: - Detection View Model Tests
    func testDetectionViewModelInitialization() throws {
        XCTAssertNotNil(detectionViewModel, "DetectionViewModel should be initialized")
        XCTAssertFalse(detectionViewModel.isAnalyzing, "Should not be analyzing initially")
        XCTAssertNil(detectionViewModel.lastAnalysisResult, "Should have no last analysis result initially")
        XCTAssertTrue(detectionViewModel.analysisHistory.isEmpty, "Should have empty analysis history initially")
        XCTAssertNil(detectionViewModel.errorMessage, "Should have no error message initially")
        XCTAssertEqual(detectionViewModel.healthTrend, .stable, "Should have stable health trend initially")
    }
    
    func testDetectionViewModelStatistics() throws {
        // Add some test results
        let testResult1 = DentalAnalysisResult(
            healthScore: 80,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        let testResult2 = DentalAnalysisResult(
            healthScore: 70,
            detectedConditions: [.healthy: 0.7],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 1.5,
            confidence: 0.6,
            recommendations: []
        )
        
        detectionViewModel.analysisHistory = [testResult1, testResult2]
        
        XCTAssertEqual(detectionViewModel.totalAnalyses, 2, "Should have 2 total analyses")
        XCTAssertEqual(detectionViewModel.averageHealthScore, 75.0, accuracy: 0.1, "Should have correct average health score")
        XCTAssertEqual(detectionViewModel.healthScoreRange, 70...80, "Should have correct health score range")
    }
    
    func testDetectionViewModelHealthTrend() throws {
        // Add test results with improving trend
        let oldResult = DentalAnalysisResult(
            healthScore: 60,
            detectedConditions: [.healthy: 0.6],
            timestamp: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.6,
            recommendations: []
        )
        
        let newResult = DentalAnalysisResult(
            healthScore: 80,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 1.5,
            confidence: 0.8,
            recommendations: []
        )
        
        detectionViewModel.analysisHistory = [newResult, oldResult]
        detectionViewModel.updateHealthTrend()
        
        XCTAssertEqual(detectionViewModel.healthTrend, .improving, "Should detect improving trend")
    }
    
    // MARK: - Data Manager Tests
    func testDataManagerUserProfile() throws {
        let dataManager = DataManager.shared
        let testProfile = UserProfile(age: 30, preferences: ["test"], analysisHistory: [])
        
        dataManager.saveUserProfile(testProfile)
        let savedProfile = dataManager.userProfile
        
        XCTAssertEqual(savedProfile.age, 30, "Should save age correctly")
        XCTAssertEqual(savedProfile.preferences, ["test"], "Should save preferences correctly")
    }
    
    func testDataManagerAnalysisHistory() throws {
        let dataManager = DataManager.shared
        let testResult = DentalAnalysisResult(
            healthScore: 75,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        dataManager.addAnalysisResult(testResult)
        let history = dataManager.analysisHistory
        
        XCTAssertEqual(history.count, 1, "Should have 1 analysis result")
        XCTAssertEqual(history.first?.healthScore, 75, "Should save health score correctly")
    }
    
    func testDataManagerHealthStatistics() throws {
        let dataManager = DataManager.shared
        let testResult = DentalAnalysisResult(
            healthScore: 75,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        dataManager.addAnalysisResult(testResult)
        let stats = dataManager.getHealthStatistics()
        
        XCTAssertEqual(stats.totalAnalyses, 1, "Should have 1 total analysis")
        XCTAssertEqual(stats.avgScore, 75.0, accuracy: 0.1, "Should have correct average score")
    }
    
    // MARK: - Recommendation Engine Tests
    func testRecommendationEngine() throws {
        let recommendationEngine = RecommendationEngine()
        let testResult = DentalAnalysisResult(
            healthScore: 60,
            detectedConditions: [.cavity: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        let userProfile = UserProfile(age: 25, preferences: [], analysisHistory: [])
        let recommendations = recommendationEngine.generatePersonalizedRecommendations(for: testResult, userProfile: userProfile)
        
        XCTAssertFalse(recommendations.isEmpty, "Should generate recommendations")
        XCTAssertTrue(recommendations.contains { $0.category == .professionalCare }, "Should include professional care recommendation")
        XCTAssertTrue(recommendations.contains { $0.category == .homeCare }, "Should include home care recommendation")
    }
    
    func testRecommendationEngineAgeBased() throws {
        let recommendationEngine = RecommendationEngine()
        let testResult = DentalAnalysisResult(
            healthScore: 75,
            detectedConditions: [.healthy: 0.8],
            timestamp: Date(),
            imageURL: nil,
            analysisDuration: 2.0,
            confidence: 0.7,
            recommendations: []
        )
        
        let youngProfile = UserProfile(age: 18, preferences: [], analysisHistory: [])
        let youngRecommendations = recommendationEngine.generatePersonalizedRecommendations(for: testResult, userProfile: youngProfile)
        
        let oldProfile = UserProfile(age: 65, preferences: [], analysisHistory: [])
        let oldRecommendations = recommendationEngine.generatePersonalizedRecommendations(for: testResult, userProfile: oldProfile)
        
        XCTAssertNotEqual(youngRecommendations.count, oldRecommendations.count, "Should generate different recommendations for different ages")
    }
    
    // MARK: - Performance Tests
    func testImageProcessingPerformance() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        measure {
            let _ = imageProcessor.assessImageQuality(testImage)
        }
    }
    
    func testValidationPerformance() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        measure {
            let _ = validationService.validateImage(testImage)
        }
    }
    
    // MARK: - Helper Methods
    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a simple test pattern
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Add some colored rectangles to simulate teeth
            context.cgContext.setFillColor(UIColor.yellow.cgColor)
            context.cgContext.fill(CGRect(x: 50, y: 50, width: 30, height: 40))
            context.cgContext.fill(CGRect(x: 100, y: 50, width: 30, height: 40))
            context.cgContext.fill(CGRect(x: 150, y: 50, width: 30, height: 40))
        }
    }
}

// MARK: - Integration Tests
class IntegrationTests: XCTestCase {
    
    var detectionViewModel: DetectionViewModel!
    var dentalAnalysisEngine: DentalAnalysisEngine!
    
    override func setUpWithError() throws {
        detectionViewModel = DetectionViewModel()
        dentalAnalysisEngine = DentalAnalysisEngine()
    }
    
    override func tearDownWithError() throws {
        detectionViewModel = nil
        dentalAnalysisEngine = nil
    }
    
    func testCompleteAnalysisPipeline() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        let userProfile = UserProfile(age: 25, preferences: [], analysisHistory: [])
        
        let expectation = XCTestExpectation(description: "Analysis completion")
        
        Task {
            do {
                let result = try await dentalAnalysisEngine.analyzeDentalImage(testImage, userProfile: userProfile)
                
                XCTAssertNotNil(result, "Analysis result should not be nil")
                XCTAssertGreaterThanOrEqual(result.healthScore, 0, "Health score should be >= 0")
                XCTAssertLessThanOrEqual(result.healthScore, 100, "Health score should be <= 100")
                XCTAssertGreaterThanOrEqual(result.confidence, 0.0, "Confidence should be >= 0")
                XCTAssertLessThanOrEqual(result.confidence, 1.0, "Confidence should be <= 1")
                XCTAssertFalse(result.detectedConditions.isEmpty, "Should detect some conditions")
                XCTAssertFalse(result.recommendations.isEmpty, "Should generate recommendations")
                
                expectation.fulfill()
            } catch {
                XCTFail("Analysis should not fail: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testDataFlow() throws {
        let testImage = createTestImage(size: CGSize(width: 224, height: 224))
        
        let expectation = XCTestExpectation(description: "Data flow completion")
        
        Task {
            do {
                let result = try await detectionViewModel.analyzeImage(testImage)
                
                XCTAssertNotNil(result, "Analysis result should not be nil")
                XCTAssertEqual(detectionViewModel.lastAnalysisResult?.id, result.id, "Should update last analysis result")
                XCTAssertEqual(detectionViewModel.analysisHistory.count, 1, "Should add to analysis history")
                XCTAssertEqual(detectionViewModel.totalAnalyses, 1, "Should update total analyses count")
                
                expectation.fulfill()
            } catch {
                XCTFail("Analysis should not fail: \(error)")
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    private func createTestImage(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
            
            context.cgContext.setFillColor(UIColor.yellow.cgColor)
            context.cgContext.fill(CGRect(x: 50, y: 50, width: 30, height: 40))
            context.cgContext.fill(CGRect(x: 100, y: 50, width: 30, height: 40))
            context.cgContext.fill(CGRect(x: 150, y: 50, width: 30, height: 40))
        }
    }
}

// MARK: - Mock Objects
class MockDetectionService: DetectionService {
    var mockDetections: [Detection] = []
    var shouldThrowError = false
    
    func detect(in image: CGImage) throws -> [Detection] {
        if shouldThrowError {
            throw ModelError.inferenceFailed(NSError(domain: "Test", code: 1, userInfo: nil))
        }
        return mockDetections
    }
    
    var isModelAvailable: Bool = true
    
    var modelStatus: String = "Mock Detection Service"
}

// MARK: - Test Extensions
extension DetectionViewModel {
    func updateHealthTrend() {
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
}
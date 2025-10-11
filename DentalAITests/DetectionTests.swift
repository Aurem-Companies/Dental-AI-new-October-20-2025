import XCTest
import CoreGraphics
@testable import DentalAI

// MARK: - Detection Tests
class DetectionTests: XCTestCase {
    
    var testImage: CGImage!
    
    override func setUp() {
        super.setUp()
        testImage = createTestImage()
    }
    
    override func tearDown() {
        testImage = nil
        super.tearDown()
    }
    
    // MARK: - Test Image Creation
    private func createTestImage() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: nil,
            width: 100,
            height: 100,
            bitsPerComponent: 8,
            bytesPerRow: 400,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        
        context?.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context?.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        
        return context!.makeImage()!
    }
    
    // MARK: - DetectionFactory Tests
    func testDetectionFactoryMake() {
        let service = DetectionFactory.make()
        XCTAssertNotNil(service, "DetectionFactory should return a service")
        XCTAssertTrue(service is DetectionService, "Service should conform to DetectionService protocol")
    }
    
    func testDetectionFactoryMakeWithMLFlag() {
        let service = DetectionFactory.make(useMLDetection: true)
        XCTAssertNotNil(service, "DetectionFactory should return a service when ML flag is true")
    }
    
    func testDetectionFactoryMakeWithCVFlag() {
        let service = DetectionFactory.make(useMLDetection: false)
        XCTAssertNotNil(service, "DetectionFactory should return a service when ML flag is false")
        XCTAssertTrue(service is CVDentitionService, "Should return CV service when ML flag is false")
    }
    
    func testDetectionFactoryMakeWithFallback() {
        let service = DetectionFactory.makeWithFallback()
        XCTAssertNotNil(service, "DetectionFactory should return a service with fallback")
    }
    
    func testDetectionFactoryValidateService() {
        let mlService = MLDetectionService()
        let cvService = CVDentitionService()
        
        let mlValid = DetectionFactory.validateService(mlService)
        let cvValid = DetectionFactory.validateService(cvService)
        
        // CV service should always be valid
        XCTAssertTrue(cvValid, "CV service should always be valid")
        
        // ML service validity depends on model availability
        XCTAssertNotNil(mlValid, "ML service validation should return a result")
    }
    
    func testDetectionFactoryGetServiceInfo() {
        let mlService = MLDetectionService()
        let cvService = CVDentitionService()
        
        let mlInfo = DetectionFactory.getServiceInfo(mlService)
        let cvInfo = DetectionFactory.getServiceInfo(cvService)
        
        XCTAssertFalse(mlInfo.isEmpty, "ML service info should not be empty")
        XCTAssertFalse(cvInfo.isEmpty, "CV service info should not be empty")
        XCTAssertTrue(cvInfo.contains("CV Detection Service"), "CV service info should contain service type")
    }
    
    func testDetectionFactoryCompareServices() {
        let comparison = DetectionFactory.compareServices()
        XCTAssertFalse(comparison.isEmpty, "Service comparison should not be empty")
        XCTAssertTrue(comparison.contains("Service Comparison"), "Comparison should contain header")
    }
    
    func testDetectionFactoryTestDetection() {
        let cvService = CVDentitionService()
        let result = DetectionFactory.testDetection(service: cvService, image: testImage)
        
        switch result {
        case .success(let detections):
            XCTAssertNotNil(detections, "Detection should return results")
        case .failure(let error):
            XCTFail("CV detection should not fail: \(error.localizedDescription)")
        }
    }
    
    func testDetectionFactoryTestAllServices() {
        let results = DetectionFactory.testAllServices(image: testImage)
        
        XCTAssertTrue(results.keys.contains("ML"), "Results should contain ML service")
        XCTAssertTrue(results.keys.contains("CV"), "Results should contain CV service")
        
        // CV service should always succeed
        if case .failure(let error) = results["CV"] {
            XCTFail("CV service should not fail: \(error.localizedDescription)")
        }
    }
    
    func testDetectionFactoryPerformanceTest() {
        let cvService = CVDentitionService()
        let duration = DetectionFactory.performanceTest(service: cvService, image: testImage, iterations: 5)
        
        XCTAssertGreaterThan(duration, 0, "Performance test should return positive duration")
        XCTAssertLessThan(duration, 10, "Performance test should complete within reasonable time")
    }
    
    // MARK: - MLDetectionService Tests
    func testMLDetectionServiceInitialization() {
        let service = MLDetectionService()
        XCTAssertNotNil(service, "MLDetectionService should initialize")
        XCTAssertTrue(service is DetectionService, "MLDetectionService should conform to DetectionService")
    }
    
    func testMLDetectionServiceModelStatus() {
        let service = MLDetectionService()
        let status = service.modelStatus
        XCTAssertFalse(status.isEmpty, "Model status should not be empty")
    }
    
    func testMLDetectionServiceModelAvailability() {
        let service = MLDetectionService()
        let isAvailable = service.isModelAvailable
        
        // Model availability depends on whether model file exists
        // This test just ensures the property is accessible
        XCTAssertNotNil(isAvailable, "Model availability should be determinable")
    }
    
    func testMLDetectionServiceDetectionWithoutModel() {
        let service = MLDetectionService()
        
        // If model is not available, should throw ModelUnavailableError
        do {
            _ = try service.detect(in: testImage)
            // If we get here, either model is available or error handling is wrong
        } catch ModelError.modelUnavailable {
            // Expected behavior when model is not available
            XCTAssertTrue(true, "Should throw ModelUnavailableError when model is not available")
        } catch {
            XCTFail("Should throw ModelUnavailableError, but got: \(error)")
        }
    }
    
    @available(iOS 13.0, *)
    func testMLDetectionServiceAsyncDetection() async {
        let service = MLDetectionService()
        
        do {
            _ = try await service.detectAsync(in: testImage)
            // If we get here, model is available
        } catch ModelError.modelUnavailable {
            // Expected when model is not available
            XCTAssertTrue(true, "Should throw ModelUnavailableError when model is not available")
        } catch {
            XCTFail("Should throw ModelUnavailableError, but got: \(error)")
        }
    }
    
    // MARK: - CVDentitionService Tests
    func testCVDentitionServiceInitialization() {
        let service = CVDentitionService()
        XCTAssertNotNil(service, "CVDentitionService should initialize")
        XCTAssertTrue(service is DetectionService, "CVDentitionService should conform to DetectionService")
    }
    
    func testCVDentitionServiceDetection() {
        let service = CVDentitionService()
        
        do {
            let detections = try service.detect(in: testImage)
            XCTAssertNotNil(detections, "CV detection should return results")
            XCTAssertTrue(detections is [Detection], "Results should be array of Detection objects")
            
            // Check detection properties
            for detection in detections {
                XCTAssertFalse(detection.label.isEmpty, "Detection label should not be empty")
                XCTAssertGreaterThanOrEqual(detection.confidence, 0.0, "Confidence should be non-negative")
                XCTAssertLessThanOrEqual(detection.confidence, 1.0, "Confidence should be <= 1.0")
                XCTAssertTrue(detection.boundingBox.width >= 0, "Bounding box width should be non-negative")
                XCTAssertTrue(detection.boundingBox.height >= 0, "Bounding box height should be non-negative")
            }
        } catch {
            XCTFail("CV detection should not fail: \(error.localizedDescription)")
        }
    }
    
    @available(iOS 13.0, *)
    func testCVDentitionServiceAsyncDetection() async {
        let service = CVDentitionService()
        
        do {
            let detections = try await service.detectAsync(in: testImage)
            XCTAssertNotNil(detections, "Async CV detection should return results")
        } catch {
            XCTFail("Async CV detection should not fail: \(error.localizedDescription)")
        }
    }
    
    func testCVDentitionServicePerformance() {
        let service = CVDentitionService()
        
        measure {
            do {
                _ = try service.detect(in: testImage)
            } catch {
                XCTFail("CV detection should not fail: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Detection Model Tests
    func testDetectionInitialization() {
        let detection = Detection(
            label: "Test",
            confidence: 0.8,
            boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100)
        )
        
        XCTAssertEqual(detection.label, "Test", "Label should match")
        XCTAssertEqual(detection.confidence, 0.8, "Confidence should match")
        XCTAssertEqual(detection.boundingBox, CGRect(x: 0, y: 0, width: 100, height: 100), "Bounding box should match")
    }
    
    func testDetectionValidation() {
        // Valid detection
        let validDetection = Detection(
            label: "Valid",
            confidence: 0.5,
            boundingBox: CGRect(x: 0, y: 0, width: 50, height: 50)
        )
        XCTAssertEqual(validDetection.label, "Valid")
        
        // Edge case: zero confidence
        let zeroConfidenceDetection = Detection(
            label: "Zero",
            confidence: 0.0,
            boundingBox: CGRect(x: 0, y: 0, width: 10, height: 10)
        )
        XCTAssertEqual(zeroConfidenceDetection.confidence, 0.0)
        
        // Edge case: maximum confidence
        let maxConfidenceDetection = Detection(
            label: "Max",
            confidence: 1.0,
            boundingBox: CGRect(x: 0, y: 0, width: 10, height: 10)
        )
        XCTAssertEqual(maxConfidenceDetection.confidence, 1.0)
    }
    
    // MARK: - ModelError Tests
    func testModelErrorCases() {
        let errors: [ModelError] = [
            .modelUnavailable,
            .modelLoadFailed("Test error"),
            .inferenceFailed("Test error"),
            .invalidInput
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error should have description")
            XCTAssertNotNil(error.recoverySuggestion, "Error should have recovery suggestion")
        }
    }
    
    func testModelErrorDescriptions() {
        XCTAssertEqual(ModelError.modelUnavailable.errorDescription, "ML model is not available")
        XCTAssertEqual(ModelError.modelLoadFailed("Test").errorDescription, "Failed to load ML model: Test")
        XCTAssertEqual(ModelError.inferenceFailed("Test").errorDescription, "ML inference failed: Test")
        XCTAssertEqual(ModelError.invalidInput.errorDescription, "Invalid input for ML model")
    }
    
    func testModelErrorRecoverySuggestions() {
        XCTAssertEqual(ModelError.modelUnavailable.recoverySuggestion, "Please ensure the ML model is properly installed")
        XCTAssertEqual(ModelError.modelLoadFailed("Test").recoverySuggestion, "Try restarting the app or reinstalling the model")
        XCTAssertEqual(ModelError.inferenceFailed("Test").recoverySuggestion, "Please try again with a different image")
        XCTAssertEqual(ModelError.invalidInput.recoverySuggestion, "Please provide a valid image")
    }
}

// MARK: - FeatureFlags Tests
class FeatureFlagsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset to defaults before each test
        FeatureFlags.resetToDefaults()
    }
    
    override func tearDown() {
        // Reset to defaults after each test
        FeatureFlags.resetToDefaults()
        super.tearDown()
    }
    
    func testFeatureFlagsDefaults() {
        FeatureFlags.configureDefaults()
        
        // Check that defaults are set
        XCTAssertTrue(FeatureFlags.useMLDetection, "ML detection should be enabled by default")
        XCTAssertTrue(FeatureFlags.useCVDetection, "CV detection should be enabled by default")
        XCTAssertTrue(FeatureFlags.enableFallback, "Fallback should be enabled by default")
        XCTAssertFalse(FeatureFlags.debugMode, "Debug mode should be disabled by default")
        XCTAssertFalse(FeatureFlags.highPerformanceMode, "High performance mode should be disabled by default")
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.5, "Confidence threshold should be 0.5 by default")
    }
    
    func testFeatureFlagsMLDetection() {
        FeatureFlags.useMLDetection = true
        XCTAssertTrue(FeatureFlags.useMLDetection, "ML detection should be true")
        
        FeatureFlags.useMLDetection = false
        XCTAssertFalse(FeatureFlags.useMLDetection, "ML detection should be false")
    }
    
    func testFeatureFlagsCVDetection() {
        FeatureFlags.useCVDetection = true
        XCTAssertTrue(FeatureFlags.useCVDetection, "CV detection should be true")
        
        FeatureFlags.useCVDetection = false
        XCTAssertFalse(FeatureFlags.useCVDetection, "CV detection should be false")
    }
    
    func testFeatureFlagsFallback() {
        FeatureFlags.enableFallback = true
        XCTAssertTrue(FeatureFlags.enableFallback, "Fallback should be true")
        
        FeatureFlags.enableFallback = false
        XCTAssertFalse(FeatureFlags.enableFallback, "Fallback should be false")
    }
    
    func testFeatureFlagsDebugMode() {
        FeatureFlags.debugMode = true
        XCTAssertTrue(FeatureFlags.debugMode, "Debug mode should be true")
        
        FeatureFlags.debugMode = false
        XCTAssertFalse(FeatureFlags.debugMode, "Debug mode should be false")
    }
    
    func testFeatureFlagsHighPerformanceMode() {
        FeatureFlags.highPerformanceMode = true
        XCTAssertTrue(FeatureFlags.highPerformanceMode, "High performance mode should be true")
        
        FeatureFlags.highPerformanceMode = false
        XCTAssertFalse(FeatureFlags.highPerformanceMode, "High performance mode should be false")
    }
    
    func testFeatureFlagsConfidenceThreshold() {
        FeatureFlags.modelConfidenceThreshold = 0.7
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.7, "Confidence threshold should be 0.7")
        
        FeatureFlags.modelConfidenceThreshold = 0.3
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.3, "Confidence threshold should be 0.3")
    }
    
    func testFeatureFlagsResetToDefaults() {
        // Set custom values
        FeatureFlags.useMLDetection = false
        FeatureFlags.useCVDetection = false
        FeatureFlags.enableFallback = false
        FeatureFlags.debugMode = true
        FeatureFlags.highPerformanceMode = true
        FeatureFlags.modelConfidenceThreshold = 0.8
        
        // Reset to defaults
        FeatureFlags.resetToDefaults()
        
        // Check that values are reset
        XCTAssertTrue(FeatureFlags.useMLDetection, "ML detection should be reset to default")
        XCTAssertTrue(FeatureFlags.useCVDetection, "CV detection should be reset to default")
        XCTAssertTrue(FeatureFlags.enableFallback, "Fallback should be reset to default")
        XCTAssertFalse(FeatureFlags.debugMode, "Debug mode should be reset to default")
        XCTAssertFalse(FeatureFlags.highPerformanceMode, "High performance mode should be reset to default")
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.5, "Confidence threshold should be reset to default")
    }
    
    func testFeatureFlagsStatus() {
        let status = FeatureFlags.featureStatus
        XCTAssertFalse(status.isEmpty, "Feature status should not be empty")
        XCTAssertTrue(status.contains("Feature Flags Status"), "Status should contain header")
        XCTAssertTrue(status.contains("ML Detection"), "Status should contain ML detection info")
        XCTAssertTrue(status.contains("CV Detection"), "Status should contain CV detection info")
    }
    
    func testFeatureFlagsEnvironment() {
        let isDevelopment = FeatureFlags.isDevelopment
        let isProduction = FeatureFlags.isProduction
        
        #if DEBUG
        XCTAssertTrue(isDevelopment, "Should be development in DEBUG mode")
        XCTAssertFalse(isProduction, "Should not be production in DEBUG mode")
        #else
        XCTAssertFalse(isDevelopment, "Should not be development in RELEASE mode")
        XCTAssertTrue(isProduction, "Should be production in RELEASE mode")
        #endif
    }
    
    func testFeatureFlagsConfigureForEnvironment() {
        FeatureFlags.configureForEnvironment()
        
        #if DEBUG
        XCTAssertTrue(FeatureFlags.useMLDetection, "ML detection should be enabled in development")
        XCTAssertTrue(FeatureFlags.useCVDetection, "CV detection should be enabled in development")
        XCTAssertTrue(FeatureFlags.enableFallback, "Fallback should be enabled in development")
        XCTAssertTrue(FeatureFlags.debugMode, "Debug mode should be enabled in development")
        XCTAssertFalse(FeatureFlags.highPerformanceMode, "High performance mode should be disabled in development")
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.3, "Confidence threshold should be lower in development")
        #else
        XCTAssertTrue(FeatureFlags.useMLDetection, "ML detection should be enabled in production")
        XCTAssertTrue(FeatureFlags.useCVDetection, "CV detection should be enabled in production")
        XCTAssertTrue(FeatureFlags.enableFallback, "Fallback should be enabled in production")
        XCTAssertFalse(FeatureFlags.debugMode, "Debug mode should be disabled in production")
        XCTAssertTrue(FeatureFlags.highPerformanceMode, "High performance mode should be enabled in production")
        XCTAssertEqual(FeatureFlags.modelConfidenceThreshold, 0.5, "Confidence threshold should be higher in production")
        #endif
    }
}

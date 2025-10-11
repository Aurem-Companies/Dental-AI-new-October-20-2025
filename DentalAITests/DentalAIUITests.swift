import XCTest
import UIKit
@testable import DentalAI

final class DentalAIUITests: XCTestCase {
    
    var app: XCUIApplication!
    var analysisEngine: DentalAnalysisEngine!
    var imageProcessor: MockImageProcessor!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Initialize test app
        app = XCUIApplication()
        app.launch()
        
        // Initialize test dependencies
        imageProcessor = MockImageProcessor()
        analysisEngine = DentalAnalysisEngine(imageProcessor: imageProcessor)
    }
    
    override func tearDownWithError() throws {
        app = nil
        analysisEngine = nil
        imageProcessor = nil
    }
    
    // MARK: - Poor Lighting Scenario Tests
    
    func testPoorLightingImageCapture() throws {
        // Test image capture in poor lighting conditions
        let poorLightingImage = createPoorLightingImage()
        
        // Mock poor lighting quality assessment
        let poorQuality = ImageQuality(poor: true, issues: ["Image too dark", "Low contrast"])
        imageProcessor.mockImageQuality = poorQuality
        
        // Test the analysis
        let result = await analysisEngine.analyzeDentalImage(poorLightingImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Image too dark"))
                XCTAssertTrue(reason.contains("Low contrast"))
            } else {
                XCTFail("Expected lowQualityImage error for poor lighting")
            }
        case .success:
            XCTFail("Analysis should fail with poor lighting image")
        }
    }
    
    func testVeryDarkImage() throws {
        // Test extremely dark image
        let darkImage = createVeryDarkImage()
        
        let darkQuality = ImageQuality(poor: true, issues: ["Image too dark", "Insufficient lighting"])
        imageProcessor.mockImageQuality = darkQuality
        
        let result = await analysisEngine.analyzeDentalImage(darkImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Image too dark"))
            } else {
                XCTFail("Expected lowQualityImage error for dark image")
            }
        case .success:
            XCTFail("Analysis should fail with very dark image")
        }
    }
    
    func testOverexposedImage() throws {
        // Test overexposed image
        let overexposedImage = createOverexposedImage()
        
        let overexposedQuality = ImageQuality(poor: true, issues: ["Image too bright", "Overexposed"])
        imageProcessor.mockImageQuality = overexposedQuality
        
        let result = await analysisEngine.analyzeDentalImage(overexposedImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Image too bright"))
            } else {
                XCTFail("Expected lowQualityImage error for overexposed image")
            }
        case .success:
            XCTFail("Analysis should fail with overexposed image")
        }
    }
    
    func testLowContrastImage() throws {
        // Test low contrast image
        let lowContrastImage = createLowContrastImage()
        
        let lowContrastQuality = ImageQuality(poor: true, issues: ["Low contrast", "Poor image quality"])
        imageProcessor.mockImageQuality = lowContrastQuality
        
        let result = await analysisEngine.analyzeDentalImage(lowContrastImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Low contrast"))
            } else {
                XCTFail("Expected lowQualityImage error for low contrast image")
            }
        case .success:
            XCTFail("Analysis should fail with low contrast image")
        }
    }
    
    func testBlurryImage() throws {
        // Test blurry image
        let blurryImage = createBlurryImage()
        
        let blurryQuality = ImageQuality(poor: true, issues: ["Image appears blurry", "Poor focus"])
        imageProcessor.mockImageQuality = blurryQuality
        
        let result = await analysisEngine.analyzeDentalImage(blurryImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("blurry"))
            } else {
                XCTFail("Expected lowQualityImage error for blurry image")
            }
        case .success:
            XCTFail("Analysis should fail with blurry image")
        }
    }
    
    // MARK: - Real-World Scenario Tests
    
    func testBathroomLighting() throws {
        // Simulate bathroom lighting conditions
        let bathroomImage = createBathroomLightingImage()
        
        let bathroomQuality = ImageQuality(poor: true, issues: ["Harsh lighting", "Shadows", "Reflections"])
        imageProcessor.mockImageQuality = bathroomQuality
        
        let result = await analysisEngine.analyzeDentalImage(bathroomImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Harsh lighting") || reason.contains("Shadows"))
            } else {
                XCTFail("Expected lowQualityImage error for bathroom lighting")
            }
        case .success:
            XCTFail("Analysis should fail with bathroom lighting")
        }
    }
    
    func testOutdoorLighting() throws {
        // Simulate outdoor lighting conditions
        let outdoorImage = createOutdoorLightingImage()
        
        let outdoorQuality = ImageQuality(poor: true, issues: ["Too bright", "Harsh shadows", "Overexposed"])
        imageProcessor.mockImageQuality = outdoorQuality
        
        let result = await analysisEngine.analyzeDentalImage(outdoorImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Too bright") || reason.contains("Overexposed"))
            } else {
                XCTFail("Expected lowQualityImage error for outdoor lighting")
            }
        case .success:
            XCTFail("Analysis should fail with outdoor lighting")
        }
    }
    
    func testIndoorDimLighting() throws {
        // Simulate dim indoor lighting
        let dimIndoorImage = createDimIndoorLightingImage()
        
        let dimQuality = ImageQuality(poor: true, issues: ["Insufficient lighting", "Too dark", "Low contrast"])
        imageProcessor.mockImageQuality = dimQuality
        
        let result = await analysisEngine.analyzeDentalImage(dimIndoorImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Insufficient lighting") || reason.contains("Too dark"))
            } else {
                XCTFail("Expected lowQualityImage error for dim indoor lighting")
            }
        case .success:
            XCTFail("Analysis should fail with dim indoor lighting")
        }
    }
    
    func testMixedLighting() throws {
        // Simulate mixed lighting conditions
        let mixedLightingImage = createMixedLightingImage()
        
        let mixedQuality = ImageQuality(poor: true, issues: ["Mixed lighting", "Inconsistent exposure", "Shadows"])
        imageProcessor.mockImageQuality = mixedQuality
        
        let result = await analysisEngine.analyzeDentalImage(mixedLightingImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Mixed lighting") || reason.contains("Inconsistent"))
            } else {
                XCTFail("Expected lowQualityImage error for mixed lighting")
            }
        case .success:
            XCTFail("Analysis should fail with mixed lighting")
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testExtremeLowLight() throws {
        // Test extremely low light conditions
        let extremeLowLightImage = createExtremeLowLightImage()
        
        let extremeQuality = ImageQuality(poor: true, issues: ["Extremely dark", "No visible details", "Insufficient data"])
        imageProcessor.mockImageQuality = extremeQuality
        
        let result = await analysisEngine.analyzeDentalImage(extremeLowLightImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Extremely dark") || reason.contains("No visible details"))
            } else {
                XCTFail("Expected lowQualityImage error for extreme low light")
            }
        case .success:
            XCTFail("Analysis should fail with extreme low light")
        }
    }
    
    func testFlashOverexposure() throws {
        // Test flash overexposure
        let flashOverexposedImage = createFlashOverexposedImage()
        
        let flashQuality = ImageQuality(poor: true, issues: ["Flash overexposure", "Too bright", "Lost details"])
        imageProcessor.mockImageQuality = flashQuality
        
        let result = await analysisEngine.analyzeDentalImage(flashOverexposedImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Flash overexposure") || reason.contains("Too bright"))
            } else {
                XCTFail("Expected lowQualityImage error for flash overexposure")
            }
        case .success:
            XCTFail("Analysis should fail with flash overexposure")
        }
    }
    
    func testBacklighting() throws {
        // Test backlighting conditions
        let backlitImage = createBacklitImage()
        
        let backlitQuality = ImageQuality(poor: true, issues: ["Backlighting", "Subject too dark", "Poor contrast"])
        imageProcessor.mockImageQuality = backlitQuality
        
        let result = await analysisEngine.analyzeDentalImage(backlitImage)
        
        switch result {
        case .failure(let error):
            if case .lowQualityImage(let reason) = error {
                XCTAssertTrue(reason.contains("Backlighting") || reason.contains("Subject too dark"))
            } else {
                XCTFail("Expected lowQualityImage error for backlighting")
            }
        case .success:
            XCTFail("Analysis should fail with backlighting")
        }
    }
    
    // MARK: - Performance Tests for Poor Lighting
    
    func testPoorLightingPerformance() throws {
        // Test performance with poor lighting images
        let poorLightingImage = createPoorLightingImage()
        let poorQuality = ImageQuality(poor: true, issues: ["Poor lighting"])
        imageProcessor.mockImageQuality = poorQuality
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = await analysisEngine.analyzeDentalImage(poorLightingImage)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should fail quickly for poor quality images
        switch result {
        case .failure:
            XCTAssertLessThan(timeElapsed, 2.0, "Poor lighting analysis should fail quickly")
        case .success:
            XCTFail("Analysis should fail with poor lighting")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createPoorLightingImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a dark image with poor contrast
            UIColor.darkGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some very dark areas
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.3))
        }
    }
    
    private func createVeryDarkImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create an extremely dark image
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createOverexposedImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create an overexposed image
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createLowContrastImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a low contrast image
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createBlurryImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create a blurry image by drawing with low opacity
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some blurry elements
            context.cgContext.setAlpha(0.3)
            UIColor.black.setFill()
            context.fill(CGRect(x: 100, y: 100, width: 800, height: 800))
        }
    }
    
    private func createBathroomLightingImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Simulate bathroom lighting with harsh shadows
            UIColor.lightGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add harsh shadows
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width * 0.3, height: size.height))
        }
    }
    
    private func createOutdoorLightingImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Simulate outdoor lighting
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add harsh shadows
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width * 0.2, height: size.height))
        }
    }
    
    private func createDimIndoorLightingImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Simulate dim indoor lighting
            UIColor.darkGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
    private func createMixedLightingImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Simulate mixed lighting
            UIColor.gray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add bright and dark areas
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: size.width * 0.5, height: size.height))
            
            UIColor.black.setFill()
            context.fill(CGRect(x: size.width * 0.5, y: 0, width: size.width * 0.5, height: size.height))
        }
    }
    
    private func createExtremeLowLightImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create extremely low light image
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add very faint details
            context.cgContext.setAlpha(0.1)
            UIColor.darkGray.setFill()
            context.fill(CGRect(x: 200, y: 200, width: 600, height: 600))
        }
    }
    
    private func createFlashOverexposedImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create flash overexposed image
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add some blown-out highlights
            UIColor.yellow.setFill()
            context.fill(CGRect(x: 300, y: 300, width: 400, height: 400))
        }
    }
    
    private func createBacklitImage() -> UIImage {
        let size = CGSize(width: 1000, height: 1000)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Create backlit image
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Add dark subject in center
            UIColor.black.setFill()
            context.fill(CGRect(x: 300, y: 300, width: 400, height: 400))
        }
    }
}

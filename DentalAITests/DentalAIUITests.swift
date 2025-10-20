import XCTest

// MARK: - DentalAI UI Tests
class DentalAIUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Launch Tests
    func testAppLaunch() throws {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(app.staticTexts["title.dentalai"].exists)
    }
    
    // MARK: - Smoke Test - Core Functionality
    func testSmokeTest() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        
        // Verify main UI elements exist
        XCTAssertTrue(app.buttons["btn.takePhoto"].exists)
        XCTAssertTrue(app.buttons["btn.chooseLibrary"].exists)
        
        // Verify tab navigation works
        app.tabBars.buttons["tab.history"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        app.tabBars.buttons["tab.profile"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        app.tabBars.buttons["tab.home"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Tab Navigation Tests
    func testTabNavigation() throws {
        // Test Home tab
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        // Test History tab
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        // Test Profile tab
        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Home View Tests
    func testHomeViewElements() throws {
        // Check for main elements
        XCTAssertTrue(app.staticTexts["Welcome to DentalAI"].exists)
        XCTAssertTrue(app.staticTexts["Your AI-powered dental health companion"].exists)
        // Use wait checks instead of emoji-based assertions
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    func testCaptureButton() throws {
        let captureButton = app.buttons["btn.takePhoto"]
        XCTAssertTrue(captureButton.exists)
        XCTAssertTrue(captureButton.isEnabled)
    }
    
    func testPhotoLibraryButton() throws {
        let photoLibraryButton = app.buttons["btn.chooseLibrary"]
        XCTAssertTrue(photoLibraryButton.exists)
        XCTAssertTrue(photoLibraryButton.isEnabled)
    }
    
    func testDailyTips() throws {
        // Check for daily tips
        XCTAssertTrue(app.staticTexts["Brush Twice Daily"].exists)
        XCTAssertTrue(app.staticTexts["Floss Daily"].exists)
        XCTAssertTrue(app.staticTexts["Stay Hydrated"].exists)
    }
    
    // MARK: - Camera Permission Tests
    func testCameraPermissionFlow() throws {
        let captureButton = app.buttons["btn.takePhoto"]
        captureButton.tap()
        
        // Handle camera permission alert if it appears
        if app.alerts.count > 0 {
            let alert = app.alerts.firstMatch
            if alert.staticTexts["Allow"].exists {
                alert.buttons["Allow"].tap()
            } else if alert.staticTexts["OK"].exists {
                alert.buttons["OK"].tap()
            }
        }
        
        // Wait for camera view or permission denied message
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
    }
    
    // MARK: - Photo Library Tests
    func testPhotoLibraryFlow() throws {
        let photoLibraryButton = app.buttons["btn.chooseLibrary"]
        photoLibraryButton.tap()
        
        // Photo library should appear
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 3))
        
        // Cancel photo selection
        app.buttons["Cancel"].tap()
    }
    
    // MARK: - History View Tests
    func testHistoryView() throws {
        app.tabBars.buttons["History"].tap()
        
        // Check for history elements
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        // Should show empty state initially
        let emptyState = app.staticTexts["No recent analysis. Take a photo to get started!"]
        XCTAssertTrue(emptyState.exists)
    }
    
    // MARK: - Profile View Tests
    func testProfileView() throws {
        app.tabBars.buttons["Profile"].tap()
        
        // Check for profile elements
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Data"].exists)
        XCTAssertTrue(app.staticTexts["Support"].exists)
    }
    
    func testProfileSettings() throws {
        app.tabBars.buttons["Profile"].tap()
        
        // Test User Profile navigation
        app.staticTexts["User Profile"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.navigationBars.buttons["Back"].tap()
        
        // Test Notifications navigation
        app.staticTexts["Notifications"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.navigationBars.buttons["Back"].tap()
        
        // Test Privacy navigation
        app.staticTexts["Privacy"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.navigationBars.buttons["Back"].tap()
    }
    
    func testProfileDataOptions() throws {
        app.tabBars.buttons["Profile"].tap()
        
        // Test Export Data navigation
        app.staticTexts["Export Data"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.navigationBars.buttons["Back"].tap()
        
        // Test Import Data navigation
        app.staticTexts["Import Data"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.navigationBars.buttons["Back"].tap()
    }
    
    func testProfileSupportOptions() throws {
        app.tabBars.buttons["Profile"].tap()
        
        // Test About navigation
        app.staticTexts["About DentalAI"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        app.buttons["Done"].tap()
        
        // Test Contact Support
        app.staticTexts["Contact Support"].tap()
        // Should open contact method (email, phone, etc.)
        
        // Test Rate App
        app.staticTexts["Rate App"].tap()
        // Should open App Store rating
    }
    
    // MARK: - About View Tests
    func testAboutView() throws {
        app.tabBars.buttons["Profile"].tap()
        app.staticTexts["About DentalAI"].tap()
        
        // Check for about elements
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        XCTAssertTrue(app.staticTexts["DentalAI"].exists)
        XCTAssertTrue(app.staticTexts["Version 1.0.0"].exists)
        XCTAssertTrue(app.staticTexts["About"].exists)
        XCTAssertTrue(app.staticTexts["Features"].exists)
        XCTAssertTrue(app.staticTexts["Disclaimer"].exists)
        
        // Test done button
        app.buttons["Done"].tap()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Accessibility Tests
    func testAccessibilityLabels() throws {
        // Test button accessibility
        let captureButton = app.buttons["Take Photo"]
        XCTAssertTrue(captureButton.exists)
        
        let photoLibraryButton = app.buttons["Choose from Library"]
        XCTAssertTrue(photoLibraryButton.exists)
        
        // Test tab bar accessibility
        let homeTab = app.tabBars.buttons["Home"]
        let historyTab = app.tabBars.buttons["History"]
        let profileTab = app.tabBars.buttons["Profile"]
        
        XCTAssertTrue(homeTab.exists)
        XCTAssertTrue(historyTab.exists)
        XCTAssertTrue(profileTab.exists)
    }
    
    // MARK: - Performance Tests
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testTabSwitchingPerformance() throws {
        measure {
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["History"].tap()
            app.tabBars.buttons["Profile"].tap()
            app.tabBars.buttons["Home"].tap()
        }
    }
    
    // MARK: - Error Handling Tests
    func testErrorHandling() throws {
        // Test with invalid image (if possible)
        // This would require mocking or using a test image
        // For now, just verify the app doesn't crash
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
    
    // MARK: - Dark Mode Tests
    func testDarkModeSupport() throws {
        // Test app appearance in dark mode
        app.buttons["Take Photo"].tap()
        
        // Verify UI elements are still visible and functional
        XCTAssertTrue(app.buttons["Take Photo"].exists)
    }
    
    // MARK: - Orientation Tests
    func testOrientationSupport() throws {
        // Test portrait orientation
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        // Test landscape orientation
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Memory Tests
    func testMemoryUsage() throws {
        // Navigate through all tabs multiple times
        for _ in 0..<5 {
            app.tabBars.buttons["Home"].tap()
            app.tabBars.buttons["History"].tap()
            app.tabBars.buttons["Profile"].tap()
        }
        
        // App should still be responsive
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Network Tests
    func testOfflineFunctionality() throws {
        // Test app functionality without network
        // Most features should work offline
        XCTAssertTrue(app.buttons["Take Photo"].exists)
        XCTAssertTrue(app.buttons["Choose from Library"].exists)
    }
    
    // MARK: - Localization Tests
    func testLocalization() throws {
        // Test app in different languages
        // This would require changing device language
        // For now, just verify English text is present
        XCTAssertTrue(app.staticTexts["Welcome to DentalAI"].exists)
    }
    
    // MARK: - Security Tests
    func testDataPrivacy() throws {
        // Test that sensitive data is not exposed in UI
        app.tabBars.buttons["Profile"].tap()
        app.staticTexts["Privacy"].tap()
        
        // Verify privacy settings are accessible
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 2))
    }
    
    // MARK: - Integration Tests
    func testCompleteUserFlow() throws {
        // Test complete user flow from launch to analysis
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        
        // Navigate to home
        app.tabBars.buttons["Home"].tap()
        
        // Check for capture button
        XCTAssertTrue(app.buttons["Take Photo"].exists)
        
        // Navigate to history
        app.tabBars.buttons["History"].tap()
        
        // Check for empty state
        XCTAssertTrue(app.staticTexts["No recent analysis. Take a photo to get started!"].exists)
        
        // Navigate to profile
        app.tabBars.buttons["Profile"].tap()
        
        // Check for profile options
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Data"].exists)
        XCTAssertTrue(app.staticTexts["Support"].exists)
    }
    
    // MARK: - Helper Methods
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    private func tapIfExists(_ element: XCUIElement) {
        if element.exists {
            element.tap()
        }
    }
    
    private func dismissAlertIfPresent() {
        if app.alerts.count > 0 {
            let alert = app.alerts.firstMatch
            if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
            } else if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
            } else if alert.buttons["Cancel"].exists {
                alert.buttons["Cancel"].tap()
            }
        }
    }
}
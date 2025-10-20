# DentalAI UI Testing Guide

## Prerequisites

- Xcode 15.0 or later (required for iOS 17.0 deployment target)
- macOS with Apple Silicon or Intel processor
- iOS Simulator with iPhone 15 (or compatible device)

## Running Tests

### Method 1: Command Line (Recommended)
```bash
# Make script executable
chmod +x TEST_SCRIPT.sh

# Run all UI tests
./TEST_SCRIPT.sh
```

### Method 2: Manual xcodebuild
```bash
# For workspace-based project
xcodebuild test \
  -workspace "DentalAI.xcworkspace" \
  -scheme "DentalAI" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | tee test.out

# For project-based (if no workspace)
xcodebuild test \
  -project "DentalAI.xcodeproj" \
  -scheme "DentalAI" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | tee test.out
```

### Method 3: Xcode GUI
1. Open `DentalAI.xcodeproj` in Xcode
2. Select iPhone 15 simulator from device menu
3. Press `⌘ + U` or Product → Test
4. View results in Test Navigator (`⌘ + 6`)

## Test Coverage

### Core Functionality Tests
- **testAppLaunch()**: Verifies app launches successfully
- **testSmokeTest()**: Comprehensive smoke test covering:
  - App launch verification
  - Main UI button existence (`btn.takePhoto`, `btn.chooseLibrary`)
  - Tab navigation (`tab.home`, `tab.history`, `tab.profile`)

### UI Element Tests
- **testCaptureButton()**: Tests Take Photo button functionality
- **testPhotoLibraryButton()**: Tests Choose from Library button
- **testTabNavigation()**: Tests all tab transitions

### Permission Flow Tests
- **testCameraPermissionFlow()**: Tests camera permission handling
- **testPhotoLibraryFlow()**: Tests photo library access

### Navigation Tests
- **testHistoryView()**: Tests history screen
- **testProfileView()**: Tests profile screen
- **testProfileSettings()**: Tests profile navigation
- **testProfileDataOptions()**: Tests data export/import
- **testProfileSupportOptions()**: Tests support features

## Expected Output

### Successful Test Run
```
Test Suite 'DentalAIUITests' started at 2025-10-20 13:30:00.000
Test Case '-[DentalAIUITests testAppLaunch]' started.
Test Case '-[DentalAIUITests testAppLaunch]' passed (5.123 seconds).
Test Case '-[DentalAIUITests testSmokeTest]' started.
Test Case '-[DentalAIUITests testSmokeTest]' passed (8.456 seconds).
...
Test Suite 'DentalAIUITests' passed at 2025-10-20 13:32:15.000
     Executed 15 tests, with 0 failures (0 unexpected) in 135.000 (135.000) seconds
```

### Key Success Indicators
- ✅ All tests pass without failures
- ✅ App launches within 5 seconds
- ✅ UI elements found via accessibility identifiers
- ✅ Tab navigation works smoothly
- ✅ Permission dialogs handled gracefully

## Troubleshooting

### Test Failures

#### "Element not found" errors
**Problem**: UI elements not found by accessibility identifiers
**Solution**: 
1. Verify ContentView.swift has correct `accessibilityIdentifier()` modifiers
2. Check identifier names match between ContentView and tests
3. Ensure elements are visible when tests run

#### "App launch timeout" errors
**Problem**: App takes too long to launch
**Solution**:
1. Check for compilation errors in build
2. Verify Info.plist is properly configured
3. Ensure no blocking operations in app startup

#### "Permission dialog" failures
**Problem**: Tests fail on permission dialogs
**Solution**:
1. Tests automatically handle permission dialogs
2. Check camera/photo library permissions in Settings
3. Reset simulator if permissions are stuck

#### "Simulator not available" errors
**Problem**: iPhone 15 simulator not found
**Solution**:
1. Install iPhone 15 simulator: Xcode → Preferences → Components
2. Use different simulator: `name=iPhone 14` or `name=iPhone 13`
3. List available simulators: `xcrun simctl list devices`

### Performance Issues

#### Slow test execution
**Solution**:
1. Close other apps to free memory
2. Use faster simulator (iPhone 15 Pro)
3. Reduce test timeout values if needed

#### Memory warnings
**Solution**:
1. Reset simulator: Device → Erase All Content and Settings
2. Restart Xcode
3. Check for memory leaks in app code

## Debugging Tests

### Enable Verbose Logging
```bash
# Run tests with verbose output
xcodebuild test \
  -workspace "DentalAI.xcworkspace" \
  -scheme "DentalAI" \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -verbose \
  | tee test.out
```

### Check Test Results
```bash
# View last 60 lines of test output
tail -60 test.out

# Search for failures
grep -i "failed\|error\|exception" test.out

# Search for specific test
grep -i "testSmokeTest" test.out
```

### Manual Verification
1. **Launch App**: Run app manually in simulator
2. **Check Elements**: Verify buttons exist and are tappable
3. **Test Navigation**: Manually test tab switching
4. **Permission Flow**: Test camera/photo library access

## Continuous Integration

### GitHub Actions Example
```yaml
- name: Run UI Tests
  run: |
    xcodebuild test \
      -workspace DentalAI.xcworkspace \
      -scheme DentalAI \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -resultBundlePath TestResults.xcresult
      
- name: Upload Test Results
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: test-results
    path: TestResults.xcresult
```

### Best Practices
- ✅ Run tests before every commit
- ✅ Keep tests fast (<2 minutes total)
- ✅ Use stable accessibility identifiers
- ✅ Handle permission dialogs gracefully
- ✅ Test on multiple device sizes
- ✅ Don't rely on network in tests

## Test Maintenance

### Adding New Tests
1. Add accessibility identifiers to new UI elements
2. Create test methods following naming convention: `test[FeatureName]()`
3. Use stable assertions (avoid emoji/navigationBars)
4. Include proper error handling

### Updating Existing Tests
1. Update accessibility identifiers if UI changes
2. Adjust timeouts if needed
3. Update expected behavior if app logic changes
4. Maintain backward compatibility

The test suite is designed to be stable, fast, and maintainable for continuous integration.

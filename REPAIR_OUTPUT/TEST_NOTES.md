# DentalAI UI Test Instructions

## Prerequisites

- Xcode 15.0 or later (required for iOS 17.0 deployment target)
- macOS with Apple Silicon or Intel processor
- iOS Simulator or physical device running iOS 17.0+

## Setup Steps

### 1. Add Info.plist to Project (Required)

The repair process created `DentalAI/Info.plist` but it needs to be added to the Xcode project:

1. Open `DentalAI.xcodeproj` in Xcode
2. In Project Navigator, select the `DentalAI` folder
3. Right-click → "Add Files to DentalAI..."
4. Navigate to and select `DentalAI/Info.plist`
5. Ensure "Copy items if needed" is **unchecked** (file is already in place)
6. Ensure "Add to targets" has **DentalAI** checked
7. Click "Add"

### 2. Verify Build Settings

1. Select project in Navigator → Select "DentalAI" target
2. Build Settings tab → Search "iOS Deployment Target"
3. Verify it shows **17.0** for both Debug and Release
4. Search "ENABLE_BITCODE" → Verify it's set to **NO**
5. Search "LD_RUNPATH_SEARCH_PATHS" → Verify includes:
   - `@executable_path/Frameworks`
   - `@loader_path/Frameworks`

### 3. Verify Model Files (If Applicable)

If you have ML model files (.mlmodel, .onnx, .pt):

1. Select project → Select "DentalAI" target
2. Build Phases tab → "Copy Bundle Resources"
3. Ensure model files are listed here
4. If not, click "+" and add them

## Running UI Tests in Xcode

### Method 1: Run All UI Tests

1. Open `DentalAI.xcodeproj` in Xcode
2. Select a simulator: **iPhone 15 Pro (iOS 17.0+)** from device menu
3. Press `⌘ + U` or Product → Test
4. Wait for tests to complete (30-60 seconds)
5. View results in Test Navigator (`⌘ + 6`)

### Method 2: Run Smoke Test Only

1. Open `DentalAITests/DentalAIUITests.swift`
2. Find the `testSmokeTest()` method (line ~25)
3. Click the **diamond icon** in the gutter next to the test method
4. Test will run in ~5-10 seconds
5. Green checkmark = pass, Red X = fail

### Method 3: Run from Terminal

```bash
# Navigate to project directory
cd "/Users/adammnikzad/DentalAI-IOS (Updated as of Oct 10 2025)"

# Run tests on specific simulator
xcodebuild test \
  -workspace DentalAI.xcworkspace \
  -scheme DentalAI \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'

# Or run with project file
xcodebuild test \
  -project DentalAI.xcodeproj \
  -scheme DentalAI \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0'
```

## Test Coverage

### Smoke Test (`testSmokeTest`)
**Purpose**: Verify core app functionality without flakiness

**What It Tests**:
- ✅ App launches successfully within 5 seconds
- ✅ Main UI buttons exist: "Take Photo", "Choose from Library"
- ✅ Tab navigation works: Home → History → Profile → Home
- ✅ Navigation bars display correct titles

**Expected Result**: Pass in ~5 seconds

### Additional Tests Available

The test suite includes comprehensive tests for:
- **Launch Tests**: App initialization and foreground state
- **Tab Navigation**: All tab transitions
- **Home View Elements**: Main screen components
- **Camera/Photo Permissions**: Permission request flow
- **History View**: Empty state and data display
- **Profile View**: Settings, data export, support options
- **Accessibility**: VoiceOver and accessibility labels
- **Performance**: Launch time, memory usage
- **Dark Mode**: UI appearance in dark/light modes
- **Orientation**: Portrait/landscape support

## Troubleshooting

### Test Fails: "Camera access denied"
**Solution**: This is expected on first run. The test handles permission dialogs automatically.

### Test Fails: "Navigation bar not found"
**Solution**: Check that the app's main view uses the correct navigation bar titles:
- Home: "🦷 DentalAI"
- History: "📋 History"
- Profile: "👤 Profile"

### Build Fails: "xcodebuild requires Xcode"
**Solution**: Command line tools alone are insufficient. Install full Xcode from App Store.

### Build Fails: "No such file or directory: Info.plist"
**Solution**: Follow "Add Info.plist to Project" steps above.

### Build Fails: "Unsupported iOS version"
**Solution**: 
1. Update simulator: Xcode → Preferences → Components
2. Or change deployment target back to 16.0 (not recommended)

### Test Timeout
**Solution**: Increase timeout in test:
```swift
XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10)) // Increase to 10 seconds
```

## Continuous Integration

For CI/CD pipelines (GitHub Actions, GitLab CI, etc.):

```yaml
# Example GitHub Actions workflow
- name: Run UI Tests
  run: |
    xcodebuild test \
      -project DentalAI.xcodeproj \
      -scheme DentalAI \
      -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=17.0' \
      -resultBundlePath TestResults.xcresult
      
- name: Upload Test Results
  uses: actions/upload-artifact@v3
  if: always()
  with:
    name: test-results
    path: TestResults.xcresult
```

## Test Reports

View detailed test reports:

1. After running tests, go to Report Navigator (`⌘ + 9`)
2. Click latest test run
3. Expand failed tests to see error details
4. Click "Open in Assistant Editor" for side-by-side code view

## Best Practices

- ✅ Run smoke test before every commit
- ✅ Run full test suite before merging to main
- ✅ Keep tests fast (<1 minute total)
- ✅ Don't rely on network in tests
- ✅ Use stable UI element identifiers
- ✅ Handle permission dialogs gracefully
- ✅ Test on multiple device sizes

## Need Help?

- Xcode Test Documentation: https://developer.apple.com/documentation/xctest
- UI Testing Guide: https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/
- WWDC Sessions: Search "UI Testing" on developer.apple.com


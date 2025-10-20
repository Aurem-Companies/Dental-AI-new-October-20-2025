# DentalAI Build Repair Notes

## What Broke

- **Compile Error**: `DetectionViewModel` called `DataManager.clearAllAnalysisHistory()` which didn't exist
- **Missing Feature Flag**: No `useONNXDetection` flag in `FeatureFlags`, causing inconsistency with detection services
- **Outdated iOS Target**: Project was targeting iOS 16.0 instead of required iOS 17.0
- **Missing Info.plist**: Main app target had no Info.plist with required privacy permissions
- **Weak Fallback Logic**: DetectionFactory didn't properly handle missing models or service failures
- **No Model Loading Helper**: No safe way to load models with proper error handling
- **Incomplete UI Tests**: Missing basic smoke test for core app functionality

## What Changed

### 1. DataManager.swift
- Added `clearAllAnalysisHistory()` method to permanently clear analysis data
- Clears UserDefaults keys: `analysisHistory`, `lastAnalysisResults`, `recentDetections`
- Safely removes Application Support/DentalAI/Analysis directory with DEBUG logging

### 2. FeatureFlags.swift
- Added `useONNXDetection` flag with getter/setter using UserDefaults
- Updated `configureDefaults()` to set ONNX flag default to `false`
- Updated `resetToDefaults()` to include ONNX flag
- Updated `featureStatus` to display ONNX detection state
- Updated `configureForEnvironment()` for both DEBUG and RELEASE with ONNX=false

### 3. DetectionFactory.swift
- Changed `make()` to use `makeWithFallback()` for resilient service creation
- Added `makeWithFeatureFlags()` to respect all three detection flags (ML, ONNX, CV)
- Rewrote `makeWithFallback()` with proper try-catch and fallback chain: ML → ONNX → CV
- Added ONNX service support in `validateService()` and `getServiceInfo()`
- Updated `compareServices()` to include ONNX service status
- Added ONNX to `testAllServices()` for comprehensive testing
- Added ONNX configuration in `configureService()`
- Added ONNX capabilities in `getServiceCapabilities()`
- Added `ModelLoadError` enum for typed model loading errors
- Added `modelURL(named:ext:)` helper function for safe Bundle resource loading

### 4. project.pbxproj
- Updated all `IPHONEOS_DEPLOYMENT_TARGET` from 16.0 to 17.0 (4 occurrences)
- Affects: Debug/Release configurations for app and test targets

### 5. Info.plist (NEW FILE)
- Created Info.plist for main app target with required privacy strings
- Added `NSCameraUsageDescription` for camera access
- Added `NSPhotoLibraryUsageDescription` for photo library read access
- Added `NSPhotoLibraryAddUsageDescription` for photo library write access
- Includes standard iOS app configuration keys and scene manifest

### 6. DentalAIUITests.swift
- Added `testSmokeTest()` - comprehensive smoke test covering:
  - App launch verification
  - Main UI button existence (Take Photo, Choose from Library)
  - Tab navigation (Home, History, Profile)
  - Simple, non-flaky assertions for stable CI/CD

## Build Settings Verified

- ✅ iOS Deployment Target = 17.0 (all targets)
- ✅ Swift Language Version = Swift 5
- ✅ ENABLE_BITCODE = NO
- ✅ LD_RUNPATH_SEARCH_PATHS includes @executable_path/Frameworks and @loader_path/Frameworks

## Feature Flag Defaults

### DEBUG Environment
- ML Detection: **true**
- CV Detection: **true**
- ONNX Detection: **false**
- Fallback Enabled: **true**

### RELEASE Environment
- ML Detection: **true**
- CV Detection: **true**
- ONNX Detection: **false**
- Fallback Enabled: **true**

## Fallback Logic

The detection service selection now follows this chain:

1. If `useMLDetection` → Try ML service, fallback to CV if fails and `enableFallback=true`
2. Else if `useONNXDetection` → Try ONNX service, fallback to CV if fails and `enableFallback=true`
3. Else → Use CV service (always available)

This ensures the app **never crashes** due to missing models.

## Syntax Validation

All modified files passed Swift syntax checks:
- ✅ DataManager.swift
- ✅ FeatureFlags.swift
- ✅ DetectionFactory.swift
- ✅ DentalAIUITests.swift
- ✅ Info.plist (valid XML)

## Known Limitations

- **xcodebuild requires Xcode**: Command line tools alone cannot build iOS projects
- Info.plist must be manually added to Xcode project target (see TEST_NOTES.md)
- Model files (.mlmodel, .onnx) must be in "Copy Bundle Resources" phase


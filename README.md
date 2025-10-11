# DentalAI - iOS Dental Health Analysis App

A comprehensive iOS application that uses AI-powered image analysis to help users monitor their dental health by analyzing photos of their teeth and providing personalized recommendations.

## Features

### 🦷 Core Functionality
- **Photo Capture**: Take photos of your teeth using the device camera
- **AI Analysis**: Advanced computer vision algorithms analyze dental conditions
- **Condition Detection**: Identifies cavities, gingivitis, discoloration, plaque, and more
- **Personalized Recommendations**: Tailored advice based on detected conditions
- **Progress Tracking**: Monitor your dental health over time
- **Health Scoring**: Overall dental health score from 0-100

### 📱 User Experience
- **Intuitive Interface**: Clean, modern SwiftUI design
- **Real-time Validation**: Image quality assessment before analysis
- **Detailed Results**: Comprehensive analysis with confidence scores
- **History Tracking**: View past analyses and trends
- **Export/Import**: Backup and restore your data

### 🔒 Privacy & Security
- **Local Processing**: On-device image analysis for privacy
- **Data Encryption**: Secure storage of user data
- **HIPAA Compliance**: Medical data handling best practices
- **User Control**: Full control over data sharing and deletion

## Technical Architecture

### Core Components
- **DentalAnalysisEngine**: Main AI analysis engine with rule-based and ML components
- **ImageProcessor**: Image enhancement, quality assessment, and preprocessing
- **RecommendationEngine**: Personalized recommendation generation
- **ValidationService**: Input validation and data integrity checks
- **DataManager**: User data persistence and management

### AI/ML Pipeline
1. **Image Preprocessing**: Enhancement, cropping, and quality assessment
2. **Color Analysis**: Tooth color and healthiness evaluation
3. **Edge Detection**: Structural analysis for chips and misalignment
4. **Texture Analysis**: Gum health and inflammation detection
5. **Condition Classification**: Multi-condition detection and severity assessment
6. **Recommendation Generation**: Personalized advice based on results

### Data Models
- **DentalCondition**: Enumeration of detectable conditions
- **DentalAnalysisResult**: Complete analysis results with confidence scores
- **Recommendation**: Structured advice with priority and action items
- **UserProfile**: User information and preferences
- **HealthStatistics**: Aggregated health metrics and trends

## Installation

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Setup
1. Clone the repository
2. Open `DentalAI.xcodeproj` in Xcode
3. Build and run on device or simulator
4. Grant camera permissions when prompted

## Usage

### Taking a Photo
1. Launch the app
2. Tap "Capture Photo"
3. Grant camera permissions
4. Take a clear photo of your teeth
5. Review image quality feedback
6. Tap "Analyze Photo"

### Viewing Results
1. Review overall health score
2. Check detected conditions
3. Read personalized recommendations
4. View detailed analysis
5. Track progress over time

### Managing Data
1. Access user profile settings
2. View analysis history
3. Export data for backup
4. Clear old results if needed

## AI Analysis Capabilities

### Detectable Conditions
- **Cavities**: Tooth decay detection
- **Gingivitis**: Gum inflammation
- **Discoloration**: Tooth staining and yellowing
- **Plaque**: Bacterial buildup
- **Tartar**: Hardened plaque
- **Dead Tooth**: Non-vital teeth
- **Root Canal**: Treatment indicators
- **Chipped Teeth**: Structural damage
- **Misaligned Teeth**: Alignment issues
- **Healthy**: Good oral health

### Analysis Methods
- **Rule-based Detection**: Color, texture, and shape analysis
- **Computer Vision**: Edge detection and pattern recognition
- **Machine Learning**: Trained models for condition classification
- **Confidence Scoring**: Reliability assessment for each detection

## Recommendations System

### Categories
- **Home Care**: Brushing, flossing, and oral hygiene
- **Professional Care**: Dental appointments and treatments
- **Lifestyle Changes**: Diet, habits, and preventive measures
- **Product Recommendations**: Toothpaste, mouthwash, and tools
- **Emergency Care**: Urgent dental situations

### Personalization
- **Age-based**: Recommendations tailored to user age
- **History-based**: Advice based on past analyses
- **Trend-based**: Guidance based on health trends
- **Seasonal**: Time-appropriate recommendations

## Data Management

### Storage
- **Local Storage**: UserDefaults for settings and metadata
- **Image Files**: Document directory for analysis photos
- **Backup System**: Export/import functionality
- **Data Validation**: Integrity checks and repair tools

### Privacy
- **No Cloud Storage**: All data remains on device
- **Encrypted Storage**: Secure data protection
- **User Control**: Full data ownership and deletion rights
- **Minimal Permissions**: Only camera access required

## Development

### Project Structure
```
DentalAI/
├── Models/
│   └── Models.swift
├── Views/
│   ├── ContentView.swift
│   ├── CameraView.swift
│   └── ImageAnalysisView.swift
├── Services/
│   ├── DentalAnalysisEngine.swift
│   ├── ImageProcessor.swift
│   ├── RecommendationEngine.swift
│   ├── DataManager.swift
│   └── ValidationService.swift
└── Assets.xcassets/
```

### Key Classes
- `DentalAnalysisEngine`: Main analysis logic
- `ImageProcessor`: Image processing and enhancement
- `RecommendationEngine`: Recommendation generation
- `DataManager`: Data persistence and management
- `ValidationService`: Input validation and quality checks

### Testing
- Unit tests for core analysis logic
- Integration tests for data flow
- UI tests for user interactions
- Validation tests for edge cases

## Machine Learning Setup

The DentalAI app supports both ML-based detection and computer vision fallback. See [docs/ML_MODEL_SETUP.md](docs/ML_MODEL_SETUP.md) for detailed setup instructions.

### Detection Methods
- **YOLO Detection**: Uses YOLOv5/YOLOv8 models converted to CoreML for high-accuracy detection
- **CV Detection**: Uses computer vision algorithms as a fallback
- **Automatic Fallback**: Seamlessly switches between methods based on availability

### Model Requirements
- **Format**: `.mlpackage` (CoreML package format)
- **Input**: RGB image (224x224 or 416x416 recommended)
- **Output**: Detection results with bounding boxes and confidence scores
- **Framework**: CoreML with Vision framework integration

### Quick Setup
1. **Prepare Real Data**: Organize dental images in YOLO format
2. **Train YOLO Model**: Use `scripts/train_yolo_model.py` with real dental data
3. **Convert to CoreML**: Use `scripts/convert_yolo_model.py` to convert `.pt` to `.mlpackage`
4. **Add Model**: Place your `.mlpackage` file in `DentalAI/Resources/Models/`
5. **Update Name**: Set model name in `MLDetectionService.swift`
6. **Configure Flags**: Use `FeatureFlags` to control detection method
7. **Test**: Run the app to verify detection works

### Feature Flags
```swift
// Enable ML detection (default)
FeatureFlags.useMLDetection = true

// Enable CV detection as fallback
FeatureFlags.useCVDetection = true

// Enable automatic fallback
FeatureFlags.enableFallback = true
```

### Privacy & Security
- **On-device Processing**: All ML inference happens locally
- **No Data Transmission**: Images never leave the device
- **Model Security**: Models are included in app bundle
- **User Control**: Full control over detection preferences

## Future Enhancements

### Planned Features
- **Enhanced ML Models**: Improved accuracy and speed
- **Professional Integration**: Dentist referral network
- **Tele-dentistry**: Remote consultation capabilities
- **Insurance Integration**: Coverage verification
- **Advanced Analytics**: Predictive health insights

### Technical Improvements
- **Model Training**: Custom dental AI models
- **Performance Optimization**: Faster analysis and processing
- **Accuracy Improvements**: Better condition detection
- **User Experience**: Enhanced interface and workflows

## Contributing

### Development Guidelines
1. Follow Swift coding standards
2. Write comprehensive tests
3. Document public APIs
4. Ensure privacy compliance
5. Test on multiple devices

### Code Style
- Use SwiftUI for UI components
- Follow MVVM architecture
- Implement proper error handling
- Use dependency injection
- Write self-documenting code

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This app is for informational purposes only and should not replace professional dental consultation. Always consult with a qualified dentist for medical advice and treatment.

## Support

For support, questions, or feature requests, please contact the development team or create an issue in the repository.

## Acknowledgments

- Medical professionals who provided guidance
- Open source computer vision libraries
- iOS development community
- Beta testers and feedback providers

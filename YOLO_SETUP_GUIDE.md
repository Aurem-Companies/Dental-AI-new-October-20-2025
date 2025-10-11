# YOLO Setup Guide for DentalAI

This guide provides step-by-step instructions for setting up YOLO detection in the DentalAI iOS app.

## 🚀 Quick Start

### 1. Install Dependencies
```bash
# Install Python dependencies
pip install torch coremltools ultralytics opencv-python pillow numpy

# Or use requirements.txt (create this file)
pip install -r requirements.txt
```

### 2. Train YOLO Model
```bash
# Train on real dental data
python scripts/train_yolo_model.py \
    --data /path/to/dental/dataset \
    --output dental_model.pt \
    --epochs 100

# Or use pretrained model for testing (faster)
python scripts/train_yolo_model.py --output pretrained_model.pt --pretrained

# Alternative: Use the sample model creation script
python scripts/create_sample_yolo_model.py \
    --data /path/to/dental/dataset \
    --output dental_model.pt \
    --epochs 100
```

### 3. Convert to CoreML
```bash
# Convert YOLO model to CoreML format
python scripts/convert_yolo_model.py \
    --input sample_dental_model.pt \
    --output DentalDetectionModel.mlpackage \
    --input_size 416 \
    --confidence 0.5
```

### 4. Add to iOS Project
1. Copy `DentalDetectionModel.mlpackage` to `DentalAI/Resources/Models/`
2. Open Xcode and add the file to the project
3. Build and run the app

## 📁 File Structure

```
DentalAI-IOS/
├── scripts/
│   ├── convert_yolo_model.py          # YOLO to CoreML conversion
│   ├── train_yolo_model.py           # Real data training
│   └── create_sample_yolo_model.py   # Sample model creation
├── DentalAI/
│   ├── Services/ML/
│   │   ├── MLDetectionService.swift    # YOLO detection service
│   │   └── YOLOPreprocessor.swift     # Image preprocessing
│   ├── Resources/Models/
│   │   └── DentalDetectionModel.mlpackage  # Your converted model
│   └── Config/
│       └── FeatureFlags.swift         # Detection configuration
└── docs/
    └── ML_MODEL_SETUP.md             # Detailed documentation
```

## 🔧 Configuration

### Feature Flags
```swift
// Enable YOLO detection
FeatureFlags.useMLDetection = true

// Enable CV fallback
FeatureFlags.useCVDetection = true

// Enable automatic fallback
FeatureFlags.enableFallback = true

// Adjust confidence threshold
FeatureFlags.modelConfidenceThreshold = 0.5
```

### Model Settings
```swift
// In MLDetectionService.swift
private let modelName = "DentalDetectionModel"  // Your .mlpackage filename
private let inputSize: CGFloat = 416.0          // YOLO input size
private let confidenceThreshold: Float = 0.5   // Detection confidence
private let iouThreshold: Float = 0.45         // NMS IoU threshold
```

## 🎯 Supported Classes

The YOLO model detects these dental conditions:

1. **cavity** - Tooth decay
2. **gingivitis** - Gum inflammation
3. **discoloration** - Tooth staining
4. **plaque** - Bacterial film
5. **tartar** - Hardened plaque
6. **dead_tooth** - Non-vital tooth
7. **chipped** - Broken tooth
8. **misaligned** - Crooked teeth
9. **healthy_tooth** - Good oral health
10. **gum_inflammation** - Gum disease

## 🔄 Detection Pipeline

1. **Image Capture** - User takes photo
2. **Preprocessing** - Resize to 416x416, normalize colors
3. **YOLO Inference** - Run model on preprocessed image
4. **Postprocessing** - Apply NMS, filter by confidence
5. **Coordinate Transform** - Convert back to original image space
6. **Result Display** - Show detections with bounding boxes

## 🛠️ Customization

### Adding New Classes
1. Update class labels in `MLDetectionService.swift`
2. Retrain YOLO model with new classes
3. Convert updated model to CoreML
4. Replace model file in iOS project

### Adjusting Thresholds
```swift
// Lower confidence = more detections (more false positives)
FeatureFlags.modelConfidenceThreshold = 0.3

// Higher confidence = fewer detections (more false negatives)
FeatureFlags.modelConfidenceThreshold = 0.7

// Lower IoU = more overlapping detections
private let iouThreshold: Float = 0.3

// Higher IoU = fewer overlapping detections
private let iouThreshold: Float = 0.6
```

### Performance Optimization
```swift
// Enable high performance mode
FeatureFlags.highPerformanceMode = true

// Use quantized model (smaller, faster)
python scripts/convert_yolo_model.py --input model.pt --output model.mlpackage --quantize

// Use smaller input size (faster, less accurate)
private let inputSize: CGFloat = 320.0
```

## 🐛 Troubleshooting

### Model Not Loading
- Check model file is in `DentalAI/Resources/Models/`
- Verify model name matches `modelName` in `MLDetectionService.swift`
- Ensure model is added to Xcode project target

### Poor Detection Accuracy
- Check image quality (lighting, focus, angle)
- Adjust confidence threshold
- Verify model was trained on similar data
- Check preprocessing parameters

### Performance Issues
- Use quantized model
- Reduce input size
- Enable high performance mode
- Check device compatibility

### Conversion Errors
- Verify YOLO model format (.pt file)
- Check Python dependencies
- Try different input sizes
- Use minimal model for testing

## 📊 Testing

### Unit Tests
```bash
# Run detection tests
xcodebuild test -scheme DentalAI -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual Testing
1. Take photos of teeth
2. Check detection results
3. Verify bounding box accuracy
4. Test different lighting conditions
5. Compare with CV detection fallback

## 🔗 Resources

- [YOLOv8 Documentation](https://docs.ultralytics.com/)
- [CoreML Tools](https://coremltools.readme.io/)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [DentalAI Documentation](docs/ML_MODEL_SETUP.md)

## 📞 Support

For issues with YOLO setup:
1. Check troubleshooting section
2. Enable debug mode: `FeatureFlags.debugMode = true`
3. Check console logs for errors
4. Test with CV detection fallback
5. Contact development team

---

**Note**: This guide assumes you have basic knowledge of Python, iOS development, and machine learning. For detailed technical information, see [docs/ML_MODEL_SETUP.md](docs/ML_MODEL_SETUP.md).

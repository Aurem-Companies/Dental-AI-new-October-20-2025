# Machine Learning Model Setup Guide

This guide explains how to set up and configure machine learning models for the DentalAI iOS application.

## Overview

The DentalAI app supports two detection methods:
- **ML Detection**: Uses trained CoreML models for high-accuracy detection
- **CV Detection**: Uses computer vision algorithms as a fallback

## Model Requirements

### Supported Model Formats
- `.mlpackage` (CoreML package format)
- `.mlmodel` (CoreML model format)
- `.pt` (PyTorch YOLO models - converted to CoreML)

### Model Specifications
- **Input**: RGB image (416x416 recommended for YOLO)
- **Output**: Detection results with bounding boxes and confidence scores
- **Framework**: CoreML with Vision framework integration
- **YOLO Support**: Full YOLOv5/YOLOv8 compatibility with preprocessing

## Setup Instructions

### 1. Model Preparation

#### Raw Model Weights
- Keep raw model weights (`.pt`, `.onnx`, `.h5`) in a local directory
- **DO NOT** commit these files to version control
- Recommended location: `~/DentalAI-Models/raw/`

#### Model Conversion
If you have raw model weights, convert them to CoreML format:

```bash
# Convert YOLO model to CoreML
python scripts/convert_yolo_model.py \
    --input weights/yolo_dental.pt \
    --output DentalDetectionModel.mlpackage \
    --input_size 416 \
    --confidence 0.5 \
    --iou 0.45

# Train model on real dental data
python scripts/train_yolo_model.py \
    --data /path/to/dental/dataset \
    --output dental_model.pt \
    --epochs 100

# Use pretrained model for testing (no training)
python scripts/train_yolo_model.py \
    --output pretrained_model.pt \
    --pretrained
```

### 2. Model Installation

#### Step 1: Convert Model
1. Run your conversion script to generate `.mlpackage` file
2. Ensure the model outputs detection results in the expected format

#### Step 2: Add to Project
1. Open `DentalAI.xcodeproj` in Xcode
2. Right-click on `DentalAI/Resources/Models/` folder
3. Select "Add Files to DentalAI"
4. Choose your `.mlpackage` file
5. Ensure "Add to target: DentalAI" is checked

#### Step 3: Update Model Name
Update the model name in `MLDetectionService.swift`:

```swift
private let modelName = "YourModelName" // Change this to match your .mlpackage file
```

### 3. Feature Flag Configuration

#### Toggle ML vs CV Detection
Use the feature flags to control which detection method is used:

```swift
// Enable ML detection (default)
FeatureFlags.useMLDetection = true

// Enable CV detection as fallback
FeatureFlags.useCVDetection = true

// Enable automatic fallback
FeatureFlags.enableFallback = true
```

#### Runtime Configuration
You can also change these settings at runtime:

```swift
// Switch to CV detection
FeatureFlags.useMLDetection = false

// Disable fallback
FeatureFlags.enableFallback = false

// Adjust confidence threshold
FeatureFlags.modelConfidenceThreshold = 0.7
```

## YOLO Model Development

### Creating YOLO Models

#### 1. Data Preparation
- Collect real dental images with YOLO format annotations
- Ensure diverse lighting conditions and angles
- Include various dental conditions (cavities, gingivitis, etc.)
- Use tools like LabelImg or Roboflow for annotation
- Organize dataset in YOLO format:
  ```
  dental_dataset/
  ├── images/
  │   ├── train/
  │   └── val/
  ├── labels/
  │   ├── train/
  │   └── val/
  └── dataset.yaml
  ```

#### 2. Training with YOLO
```bash
# Train on real dental data using our script
python scripts/train_yolo_model.py \
    --data /path/to/dental/dataset \
    --output dental_model.pt \
    --epochs 100 \
    --model_size n

# Or use YOLO directly
yolo train data=dental_dataset.yaml model=yolov8n.pt epochs=100 imgsz=416
```

#### 3. Conversion to CoreML
```bash
# Convert trained YOLO model
python scripts/convert_yolo_model.py \
    --input runs/train/exp/weights/best.pt \
    --output DentalDetectionModel.mlpackage \
    --input_size 416 \
    --confidence 0.5
```

### YOLO-Specific Features

#### Preprocessing
- Automatic image resizing to 416x416
- Aspect ratio preservation with padding
- RGB color space conversion
- Image quality assessment

#### Postprocessing
- Non-Maximum Suppression (NMS)
- Coordinate transformation back to original image
- Confidence threshold filtering
- Class label mapping

#### Supported Classes
- cavity
- gingivitis
- discoloration
- plaque
- tartar
- dead_tooth
- chipped
- misaligned
- healthy_tooth
- gum_inflammation

### Model Optimization

#### Quantization
```python
import coremltools as ct

# Load the model
model = ct.models.MLModel('your_model.mlmodel')

# Quantize to 16-bit
quantized_model = ct.models.neural_network.quantization_utils.quantize_weights(
    model, nbits=16
)

# Save quantized model
quantized_model.save('DentalDetectionModel_quantized.mlpackage')
```

#### Pruning
- Remove unnecessary layers
- Reduce model size while maintaining accuracy
- Test performance impact

## Testing and Validation

### Model Testing
1. Test with various image qualities
2. Validate detection accuracy
3. Check performance on different devices
4. Test fallback behavior

### Performance Testing
```swift
// Test detection performance
let service = DetectionFactory.make()
let startTime = Date()
let detections = try service.detect(in: image)
let duration = Date().timeIntervalSince(startTime)
print("Detection took \(duration) seconds")
```

### Accuracy Validation
- Compare ML vs CV detection results
- Measure confidence scores
- Validate bounding box accuracy

## Troubleshooting

### Common Issues

#### Model Not Loading
- Check model file is in the correct location
- Verify model name matches the file name
- Ensure model is added to the app target

#### Low Detection Accuracy
- Check input image quality
- Verify model was trained on similar data
- Adjust confidence threshold

#### Performance Issues
- Use quantized models
- Enable high performance mode
- Consider model pruning

### Debug Mode
Enable debug mode for detailed logging:

```swift
FeatureFlags.debugMode = true
```

This will provide:
- Model loading status
- Detection confidence scores
- Performance metrics
- Error details

## Best Practices

### Model Management
- Keep models under 100MB for mobile deployment
- Use quantized models for better performance
- Test on multiple device types
- Version control model metadata

### Privacy and Security
- All processing happens on-device
- No data is sent to external servers
- Models are included in the app bundle
- User data remains private

### Performance Optimization
- Use appropriate input image sizes
- Implement efficient preprocessing
- Cache model results when possible
- Monitor memory usage

## File Structure

```
DentalAI/
├── Resources/
│   └── Models/
│       └── DentalDetectionModel.mlpackage
├── Services/
│   ├── ML/
│   │   ├── MLDetectionService.swift
│   │   └── YOLOPreprocessor.swift
│   └── CV/
│       └── CVDentitionService.swift
├── Factories/
│   └── DetectionFactory.swift
├── Config/
│   └── FeatureFlags.swift
├── Models/
│   └── Detection.swift
└── scripts/
    ├── convert_yolo_model.py
    ├── train_yolo_model.py
    └── create_sample_yolo_model.py
```

## Support

For issues with model setup or integration:
1. Check the troubleshooting section
2. Enable debug mode for detailed logs
3. Test with CV detection as fallback
4. Contact the development team

## References

- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Vision Framework](https://developer.apple.com/documentation/vision)
- [CoreML Tools](https://coremltools.readme.io/)
- [Model Optimization Guide](https://developer.apple.com/machine-learning/core-ml/)

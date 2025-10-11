# Dental Dataset Preparation Guide

This guide explains how to prepare real dental data for training YOLO models in the DentalAI iOS app.

## 📁 Dataset Structure

Your dental dataset should be organized in the following YOLO format:

```
dental_dataset/
├── images/
│   ├── train/
│   │   ├── image_001.jpg
│   │   ├── image_002.jpg
│   │   └── ...
│   └── val/
│       ├── image_101.jpg
│       ├── image_102.jpg
│       └── ...
├── labels/
│   ├── train/
│   │   ├── image_001.txt
│   │   ├── image_002.txt
│   │   └── ...
│   └── val/
│       ├── image_101.txt
│       ├── image_102.txt
│       └── ...
└── dataset.yaml
```

## 🏷️ Annotation Format

Each label file (`.txt`) should contain one line per detection in YOLO format:

```
class_id x_center y_center width height
```

Where:
- `class_id`: Integer (0-9) representing the dental condition
- `x_center`, `y_center`: Normalized center coordinates (0-1)
- `width`, `height`: Normalized dimensions (0-1)

### Class IDs

| ID | Condition | Description |
|----|-----------|-------------|
| 0 | cavity | Tooth decay |
| 1 | gingivitis | Gum inflammation |
| 2 | discoloration | Tooth staining |
| 3 | plaque | Bacterial film |
| 4 | tartar | Hardened plaque |
| 5 | dead_tooth | Non-vital tooth |
| 6 | chipped | Broken tooth |
| 7 | misaligned | Crooked teeth |
| 8 | healthy_tooth | Good oral health |
| 9 | gum_inflammation | Gum disease |

### Example Annotation

For an image with a cavity and gingivitis:

```
0 0.5 0.3 0.2 0.4
1 0.3 0.7 0.3 0.2
```

## 🖼️ Image Requirements

### Quality Standards
- **Resolution**: Minimum 416x416 pixels (higher is better)
- **Format**: JPG or PNG
- **Lighting**: Good, even lighting
- **Focus**: Sharp, clear images
- **Angle**: Straight-on view of teeth

### Content Guidelines
- **Full mouth**: Show entire dental arch when possible
- **Close-up**: Include detailed shots of specific conditions
- **Variety**: Different lighting conditions and angles
- **Diversity**: Various ages, ethnicities, and dental conditions

## 🛠️ Annotation Tools

### Recommended Tools

1. **LabelImg** (Free)
   - Download: https://github.com/tzutalin/labelImg
   - Install: `pip install labelImg`
   - Use: `labelImg` command

2. **Roboflow** (Free/Paid)
   - Web-based annotation tool
   - URL: https://roboflow.com
   - Features: Auto-labeling, augmentation

3. **CVAT** (Free)
   - Computer Vision Annotation Tool
   - URL: https://github.com/openvinotoolkit/cvat
   - Features: Collaborative annotation

### Annotation Best Practices

1. **Consistent Labeling**
   - Use the same criteria for each condition
   - Create annotation guidelines for your team
   - Regular review sessions for consistency

2. **Bounding Box Guidelines**
   - Tight bounding boxes around the condition
   - Include some context but not too much
   - Consistent box sizes for similar conditions

3. **Quality Control**
   - Review annotations regularly
   - Use multiple annotators for validation
   - Remove low-quality images

## 📊 Dataset Statistics

### Recommended Dataset Size

| Condition | Minimum Images | Recommended |
|-----------|----------------|------------|
| cavity | 100 | 500+ |
| gingivitis | 100 | 500+ |
| discoloration | 50 | 300+ |
| plaque | 100 | 400+ |
| tartar | 50 | 200+ |
| dead_tooth | 20 | 100+ |
| chipped | 50 | 200+ |
| misaligned | 50 | 200+ |
| healthy_tooth | 200 | 1000+ |
| gum_inflammation | 50 | 200+ |

### Train/Validation Split
- **Training**: 80-90% of data
- **Validation**: 10-20% of data
- **Balance**: Ensure each class has sufficient representation

## 🔧 Dataset Creation Script

Create a `dataset.yaml` file for your dataset:

```yaml
path: /path/to/dental_dataset
train: images/train
val: images/val

nc: 10
names: ['cavity', 'gingivitis', 'discoloration', 'plaque', 'tartar', 'dead_tooth', 'chipped', 'misaligned', 'healthy_tooth', 'gum_inflammation']
```

## 🚀 Training Your Model

Once your dataset is ready:

```bash
# Train on your real dental data
python scripts/train_yolo_model.py \
    --data /path/to/dental_dataset \
    --output dental_model.pt \
    --epochs 100 \
    --model_size n

# Convert to CoreML
python scripts/convert_yolo_model.py \
    --input dental_model.pt \
    --output DentalDetectionModel.mlpackage \
    --input_size 416 \
    --confidence 0.5
```

## 📈 Data Augmentation

Consider augmenting your dataset to improve model performance:

### Recommended Augmentations
- **Rotation**: ±15 degrees
- **Brightness**: ±20%
- **Contrast**: ±20%
- **Flip**: Horizontal only (teeth are symmetric)
- **Noise**: Light Gaussian noise

### Tools for Augmentation
- **Roboflow**: Built-in augmentation
- **Albumentations**: Python library
- **imgaug**: Python library

## 🔍 Quality Assurance

### Validation Checklist
- [ ] All images have corresponding label files
- [ ] Label files are in correct YOLO format
- [ ] Class IDs match the defined mapping
- [ ] Bounding boxes are within image bounds
- [ ] No duplicate or missing annotations
- [ ] Train/validation split is balanced
- [ ] Dataset.yaml is correctly configured

### Testing Your Dataset
```bash
# Validate dataset structure
python scripts/train_yolo_model.py --data /path/to/dataset --output test.pt --pretrained
```

## 📚 Resources

### Dental Condition References
- [ADA Dental Conditions](https://www.ada.org)
- [Dental Health Guidelines](https://www.nidcr.nih.gov)
- [Oral Health Standards](https://www.who.int)

### Annotation Resources
- [YOLO Annotation Guide](https://github.com/ultralytics/yolov5/wiki/Train-Custom-Data)
- [LabelImg Tutorial](https://github.com/tzutalin/labelImg)
- [Roboflow Documentation](https://docs.roboflow.com)

## ⚠️ Important Notes

1. **Privacy**: Ensure you have proper consent for using dental images
2. **Quality**: Only use high-quality, well-lit images
3. **Consistency**: Maintain consistent annotation standards
4. **Balance**: Ensure balanced representation of all conditions
5. **Validation**: Regularly validate your annotations

## 🆘 Troubleshooting

### Common Issues

**Missing Labels**
- Check file naming consistency
- Ensure all images have corresponding label files

**Invalid Coordinates**
- Verify coordinates are normalized (0-1)
- Check bounding boxes are within image bounds

**Class Imbalance**
- Use data augmentation for underrepresented classes
- Consider collecting more data for rare conditions

**Poor Model Performance**
- Review annotation quality
- Check for consistent labeling criteria
- Ensure sufficient data for each class

---

**Remember**: Quality over quantity! A smaller, well-annotated dataset will perform better than a large, poorly-annotated one.

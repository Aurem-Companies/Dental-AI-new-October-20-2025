#!/usr/bin/env python3
"""
Create YOLO Model for DentalAI with Real Data

This script creates a YOLO model for the DentalAI iOS app using real dental data.
The model detects actual dental conditions from real images.

Usage:
    python create_sample_yolo_model.py --data /path/to/dental/dataset --output dental_model.pt
"""

import argparse
import os
import sys
import warnings
from pathlib import Path

# Suppress warnings for cleaner output
warnings.filterwarnings("ignore")

try:
    import torch
    import numpy as np
    from ultralytics import YOLO
    import yaml
    from pathlib import Path
except ImportError as e:
    print(f"Error: Missing required packages. Please install:")
    print(f"pip install torch ultralytics pyyaml")
    print(f"Original error: {e}")
    sys.exit(1)

def validate_dataset(dataset_path: str) -> bool:
    """Validate that the dataset has the correct structure."""
    dataset_path = Path(dataset_path)
    
    if not dataset_path.exists():
        print(f"Error: Dataset path does not exist: {dataset_path}")
        return False
    
    # Check for required directories
    images_dir = dataset_path / "images"
    labels_dir = dataset_path / "labels"
    
    if not images_dir.exists():
        print(f"Error: Images directory not found: {images_dir}")
        return False
    
    if not labels_dir.exists():
        print(f"Error: Labels directory not found: {labels_dir}")
        return False
    
    # Check for train/val splits
    train_images = images_dir / "train"
    val_images = images_dir / "val"
    train_labels = labels_dir / "train"
    val_labels = labels_dir / "val"
    
    if not train_images.exists():
        print(f"Error: Train images directory not found: {train_images}")
        return False
    
    if not train_labels.exists():
        print(f"Error: Train labels directory not found: {train_labels}")
        return False
    
    # Check for dataset.yaml
    dataset_yaml = dataset_path / "dataset.yaml"
    if not dataset_yaml.exists():
        print(f"Error: dataset.yaml not found: {dataset_yaml}")
        return False
    
    # Count images and labels
    train_image_count = len(list(train_images.glob("*.jpg")) + list(train_images.glob("*.png")))
    train_label_count = len(list(train_labels.glob("*.txt")))
    
    if train_image_count == 0:
        print(f"Error: No training images found in {train_images}")
        return False
    
    if train_label_count == 0:
        print(f"Error: No training labels found in {train_labels}")
        return False
    
    if train_image_count != train_label_count:
        print(f"Warning: Mismatch between images ({train_image_count}) and labels ({train_label_count})")
    
    print(f"✅ Dataset validation passed:")
    print(f"   - Training images: {train_image_count}")
    print(f"   - Training labels: {train_label_count}")
    print(f"   - Validation images: {len(list(val_images.glob('*.jpg')) + list(val_images.glob('*.png'))) if val_images.exists() else 0}")
    
    return True

def create_dataset_yaml(dataset_path: str, output_path: str) -> bool:
    """Create dataset.yaml file for YOLO training."""
    dataset_path = Path(dataset_path)
    
    # Dental class labels
    classes = [
        "cavity", "gingivitis", "discoloration", "plaque", "tartar",
        "dead_tooth", "chipped", "misaligned", "healthy_tooth", "gum_inflammation"
    ]
    
    # Create dataset configuration
    config = {
        'path': str(dataset_path.absolute()),
        'train': 'images/train',
        'val': 'images/val' if (dataset_path / "images" / "val").exists() else 'images/train',
        'nc': len(classes),
        'names': classes
    }
    
    try:
        with open(output_path, 'w') as f:
            yaml.dump(config, f, default_flow_style=False)
        print(f"✅ Created dataset.yaml: {output_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to create dataset.yaml: {e}")
        return False

def train_yolo_model(dataset_path: str, output_path: str, num_epochs: int = 100, model_size: str = 'n'):
    """Train a YOLO model on real dental data."""
    
    print(f"Training YOLO model on real dental data...")
    print(f"Dataset path: {dataset_path}")
    print(f"Output path: {output_path}")
    print(f"Training epochs: {num_epochs}")
    print(f"Model size: YOLOv8{model_size}")
    
    try:
        # Validate dataset
        print("\n1. Validating dataset...")
        if not validate_dataset(dataset_path):
            return False
        
        # Create dataset.yaml if it doesn't exist
        dataset_yaml_path = Path(dataset_path) / "dataset.yaml"
        if not dataset_yaml_path.exists():
            print("\n2. Creating dataset.yaml...")
            if not create_dataset_yaml(dataset_path, str(dataset_yaml_path)):
                return False
        else:
            print("\n2. Using existing dataset.yaml...")
        
        # Create YOLO model
        print("\n3. Creating YOLO model...")
        model = YOLO(f'yolov8{model_size}.pt')  # Start with pre-trained YOLOv8
        
        # Train the model
        print("\n4. Training model...")
        results = model.train(
            data=str(dataset_yaml_path),
            epochs=num_epochs,
            imgsz=416,
            batch=16,
            device='cpu',  # Use CPU for compatibility
            verbose=True,
            save=True,
            plots=True
        )
        
        print("\n5. Saving model...")
        # Save the trained model
        model.save(output_path)
        
        print(f"\n✅ YOLO model trained successfully!")
        print(f"Model saved to: {output_path}")
        
        # Print model info
        print(f"\nModel Information:")
        print(f"- Dataset: {dataset_path}")
        print(f"- Epochs: {num_epochs}")
        print(f"- Input size: 416x416")
        print(f"- Model size: YOLOv8{model_size}")
        
        # Calculate model size
        model_size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"- Model size: {model_size_mb:.2f} MB")
        
        # Print training results
        if hasattr(results, 'results_dict'):
            print(f"\nTraining Results:")
            for key, value in results.results_dict.items():
                print(f"- {key}: {value}")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Model training failed: {str(e)}")
        return False

def create_pretrained_yolo_model(output_path: str, model_size: str = 'n'):
    """Create a pretrained YOLO model for testing (no training)."""
    
    print(f"Creating pretrained YOLO model...")
    print(f"Output path: {output_path}")
    print(f"Model size: YOLOv8{model_size}")
    
    try:
        # Create a pretrained YOLO model
        model = YOLO(f'yolov8{model_size}.pt')
        
        # Save the model
        model.save(output_path)
        
        print(f"\n✅ Pretrained YOLO model created successfully!")
        print(f"Model saved to: {output_path}")
        
        # Calculate model size
        model_size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"- Model size: {model_size_mb:.2f} MB")
        print(f"- Note: This is a pretrained model, not trained on dental data")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Model creation failed: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Train a YOLO model for DentalAI iOS app using real dental data",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Train model on real dental dataset
    python create_sample_yolo_model.py --data /path/to/dental/dataset --output dental_model.pt --epochs 100
    
    # Use pretrained model for testing (no training)
    python create_sample_yolo_model.py --output pretrained_model.pt --pretrained
    
    # Train with different model size
    python create_sample_yolo_model.py --data /path/to/dental/dataset --output dental_model.pt --model_size s
        """
    )
    
    parser.add_argument(
        "--data", "-d",
        help="Path to dental dataset directory"
    )
    
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Path to output YOLO model (.pt file)"
    )
    
    parser.add_argument(
        "--epochs",
        type=int,
        default=100,
        help="Number of training epochs (default: 100)"
    )
    
    parser.add_argument(
        "--model_size",
        choices=['n', 's', 'm', 'l', 'x'],
        default='n',
        help="YOLO model size: n=nano, s=small, m=medium, l=large, x=xlarge (default: n)"
    )
    
    parser.add_argument(
        "--pretrained",
        action="store_true",
        help="Use pretrained model without training (faster, for testing)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.pretrained and not args.data:
        print("Error: Either --data or --pretrained must be specified")
        print("Use --data to train on real dental data")
        print("Use --pretrained to use a pretrained model for testing")
        sys.exit(1)
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(args.output)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: {output_dir}")
    
    # Create model
    if args.pretrained:
        success = create_pretrained_yolo_model(args.output, args.model_size)
    else:
        success = train_yolo_model(args.data, args.output, args.epochs, args.model_size)
    
    if success:
        print(f"\n🎉 Model created successfully!")
        print(f"Next steps:")
        print(f"1. Convert to CoreML: python convert_yolo_model.py --input {args.output} --output DentalDetectionModel.mlpackage")
        print(f"2. Copy .mlpackage to DentalAI/Resources/Models/")
        print(f"3. Build and test the iOS app")
    else:
        print(f"\n💥 Model creation failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()

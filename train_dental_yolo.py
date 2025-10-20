#!/usr/bin/env python3
"""
Comprehensive Dental YOLO Training Script
Trains a YOLO model specifically for dental condition detection
"""

import os
import sys
import argparse
import numpy as np
from pathlib import Path
import yaml
import shutil
from PIL import Image, ImageDraw, ImageFont
import random
import json

# Add scripts directory to path
sys.path.append('scripts')

try:
    from ultralytics import YOLO
    import torch
    import coremltools as ct
except ImportError as e:
    print(f"Error: Missing required packages. Please install:")
    print(f"pip install torch coremltools ultralytics pillow numpy pyyaml")
    print(f"Original error: {e}")
    sys.exit(1)

class DentalDatasetGenerator:
    """Generates synthetic dental images with annotations for training"""
    
    def __init__(self, output_dir: str, num_images: int = 1000):
        self.output_dir = Path(output_dir)
        self.num_images = num_images
        self.classes = [
            'cavity', 'gingivitis', 'discoloration', 'plaque', 'tartar',
            'dead_tooth', 'chipped', 'misaligned', 'healthy', 'gum_inflammation'
        ]
        
        # Create directory structure
        self.setup_directories()
        
    def setup_directories(self):
        """Create the required directory structure"""
        dirs = [
            self.output_dir / 'images' / 'train',
            self.output_dir / 'images' / 'val',
            self.output_dir / 'labels' / 'train',
            self.output_dir / 'labels' / 'val'
        ]
        
        for dir_path in dirs:
            dir_path.mkdir(parents=True, exist_ok=True)
            
    def generate_synthetic_dental_image(self, width: int = 416, height: int = 416) -> tuple:
        """Generate a synthetic dental image with realistic conditions"""
        # Create base image (mouth/teeth background)
        image = Image.new('RGB', (width, height), color=(240, 240, 240))
        draw = ImageDraw.Draw(image)
        
        # Draw basic mouth structure
        mouth_center_x = width // 2
        mouth_center_y = height // 2
        mouth_width = width * 0.8
        mouth_height = height * 0.6
        
        # Draw upper and lower teeth rows
        tooth_width = mouth_width / 8
        tooth_height = mouth_height / 3
        
        annotations = []
        
        # Generate 1-4 random conditions per image
        num_conditions = random.randint(1, 4)
        conditions = random.sample(self.classes, num_conditions)
        
        for i, condition in enumerate(conditions):
            # Random position for condition
            x_center = random.uniform(0.2, 0.8)
            y_center = random.uniform(0.3, 0.7)
            w = random.uniform(0.1, 0.3)
            h = random.uniform(0.1, 0.3)
            
            # Draw condition visualization
            self.draw_condition(draw, condition, x_center, y_center, w, h, width, height)
            
            # Add annotation
            class_id = self.classes.index(condition)
            annotations.append(f"{class_id} {x_center:.6f} {y_center:.6f} {w:.6f} {h:.6f}")
            
        return image, annotations
    
    def draw_condition(self, draw, condition: str, x_center: float, y_center: float, 
                      w: float, h: float, img_width: int, img_height: int):
        """Draw visual representation of dental condition"""
        x = int((x_center - w/2) * img_width)
        y = int((y_center - h/2) * img_height)
        width = int(w * img_width)
        height = int(h * img_height)
        
        colors = {
            'cavity': (139, 69, 19),      # Brown
            'gingivitis': (220, 20, 60),   # Red
            'discoloration': (255, 255, 0), # Yellow
            'plaque': (192, 192, 192),     # Silver
            'tartar': (160, 82, 45),       # Saddle brown
            'dead_tooth': (105, 105, 105), # Dim gray
            'chipped': (128, 0, 128),      # Purple
            'misaligned': (75, 0, 130),    # Indigo
            'healthy': (34, 139, 34),      # Forest green
            'gum_inflammation': (255, 69, 0) # Red orange
        }
        
        color = colors.get(condition, (128, 128, 128))
        
        # Draw condition shape
        if condition == 'cavity':
            # Draw dark circle for cavity
            draw.ellipse([x, y, x + width, y + height], fill=color, outline=(0, 0, 0), width=2)
        elif condition == 'gingivitis':
            # Draw red inflamed area
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(139, 0, 0), width=2)
        elif condition == 'discoloration':
            # Draw yellow stain
            draw.ellipse([x, y, x + width, y + height], fill=color, outline=(200, 200, 0), width=1)
        elif condition == 'plaque':
            # Draw white film
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(169, 169, 169), width=1)
        elif condition == 'tartar':
            # Draw brown buildup
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(101, 67, 33), width=2)
        elif condition == 'dead_tooth':
            # Draw dark tooth
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(64, 64, 64), width=2)
        elif condition == 'chipped':
            # Draw jagged edge
            points = [(x, y), (x + width//2, y + height//4), (x + width, y), 
                     (x + width - width//4, y + height//2), (x + width, y + height),
                     (x + width//2, y + height - height//4), (x, y + height)]
            draw.polygon(points, fill=color, outline=(64, 0, 64), width=2)
        elif condition == 'misaligned':
            # Draw rotated rectangle
            center_x, center_y = x + width//2, y + height//2
            angle = 15  # degrees
            # Simplified rotated rectangle
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(37, 0, 65), width=2)
        elif condition == 'healthy':
            # Draw clean white tooth
            draw.rectangle([x, y, x + width, y + height], fill=color, outline=(0, 100, 0), width=2)
        elif condition == 'gum_inflammation':
            # Draw inflamed gum area
            draw.ellipse([x, y, x + width, y + height], fill=color, outline=(139, 0, 0), width=2)
    
    def generate_dataset(self):
        """Generate the complete dataset"""
        print(f"Generating {self.num_images} synthetic dental images...")
        
        # Split into train/val (80/20)
        train_count = int(self.num_images * 0.8)
        val_count = self.num_images - train_count
        
        # Generate training images
        for i in range(train_count):
            image, annotations = self.generate_synthetic_dental_image()
            
            # Save image
            image_path = self.output_dir / 'images' / 'train' / f'train_{i:04d}.jpg'
            image.save(image_path, 'JPEG', quality=95)
            
            # Save annotations
            label_path = self.output_dir / 'labels' / 'train' / f'train_{i:04d}.txt'
            with open(label_path, 'w') as f:
                f.write('\n'.join(annotations))
                
            if (i + 1) % 100 == 0:
                print(f"Generated {i + 1}/{train_count} training images")
        
        # Generate validation images
        for i in range(val_count):
            image, annotations = self.generate_synthetic_dental_image()
            
            # Save image
            image_path = self.output_dir / 'images' / 'val' / f'val_{i:04d}.jpg'
            image.save(image_path, 'JPEG', quality=95)
            
            # Save annotations
            label_path = self.output_dir / 'labels' / 'val' / f'val_{i:04d}.txt'
            with open(label_path, 'w') as f:
                f.write('\n'.join(annotations))
                
            if (i + 1) % 50 == 0:
                print(f"Generated {i + 1}/{val_count} validation images")
        
        print(f"✅ Dataset generation complete!")
        print(f"Training images: {train_count}")
        print(f"Validation images: {val_count}")
    
    def create_dataset_yaml(self):
        """Create dataset.yaml file for YOLO training"""
        dataset_config = {
            'path': str(self.output_dir.absolute()),
            'train': 'images/train',
            'val': 'images/val',
            'nc': len(self.classes),
            'names': self.classes
        }
        
        yaml_path = self.output_dir / 'dataset.yaml'
        with open(yaml_path, 'w') as f:
            yaml.dump(dataset_config, f, default_flow_style=False)
        
        print(f"✅ Created dataset.yaml at {yaml_path}")
        return yaml_path

def train_yolo_model(dataset_path: str, output_path: str, epochs: int = 100, model_size: str = 'n'):
    """Train YOLO model on dental dataset"""
    print(f"🚀 Starting YOLO training...")
    print(f"Dataset: {dataset_path}")
    print(f"Output: {output_path}")
    print(f"Epochs: {epochs}")
    print(f"Model: YOLOv8{model_size}")
    
    try:
        # Load YOLO model
        model = YOLO(f'yolov8{model_size}.pt')
        
        # Train the model
        results = model.train(
            data=str(dataset_path),
            epochs=epochs,
            imgsz=416,
            batch=16,
            device='cpu',  # Use CPU for compatibility
            verbose=True,
            save=True,
            plots=True,
            project='dental_training',
            name='yolo_dental_model'
        )
        
        # Save the trained model
        model.save(output_path)
        
        print(f"✅ Training completed successfully!")
        print(f"Model saved to: {output_path}")
        
        # Print training results
        if hasattr(results, 'results_dict'):
            print(f"\nTraining Results:")
            for key, value in results.results_dict.items():
                print(f"  {key}: {value}")
        
        return True
        
    except Exception as e:
        print(f"❌ Training failed: {str(e)}")
        return False

def convert_to_coreml(input_path: str, output_path: str):
    """Convert YOLO model to CoreML format"""
    print(f"🔄 Converting YOLO model to CoreML...")
    print(f"Input: {input_path}")
    print(f"Output: {output_path}")
    
    try:
        # Load YOLO model
        model = YOLO(input_path)
        
        # Export to CoreML
        model.export(
            format='coreml',
            imgsz=416,
            optimize=True,
            half=False,
            int8=False,
            dynamic=False,
            simplify=True,
            opset=11
        )
        
        # Find the exported CoreML file
        model_dir = Path(input_path).parent
        coreml_files = list(model_dir.glob('*.mlpackage'))
        
        if coreml_files:
            # Move to desired location
            shutil.move(str(coreml_files[0]), output_path)
            print(f"✅ CoreML conversion successful!")
            print(f"CoreML model saved to: {output_path}")
            return True
        else:
            print(f"❌ CoreML file not found after export")
            return False
            
    except Exception as e:
        print(f"❌ CoreML conversion failed: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Train YOLO model for dental condition detection')
    parser.add_argument('--dataset-dir', default='dental_training_dataset', 
                       help='Directory for training dataset')
    parser.add_argument('--num-images', type=int, default=1000,
                       help='Number of synthetic images to generate')
    parser.add_argument('--epochs', type=int, default=50,
                       help='Number of training epochs')
    parser.add_argument('--model-size', default='n', choices=['n', 's', 'm', 'l', 'x'],
                       help='YOLO model size (n=nano, s=small, m=medium, l=large, x=xlarge)')
    parser.add_argument('--output-model', default='dental_yolo_model.pt',
                       help='Output path for trained model')
    parser.add_argument('--output-coreml', default='DentalDetectionModel.mlpackage',
                       help='Output path for CoreML model')
    
    args = parser.parse_args()
    
    print("🦷 Dental YOLO Training Pipeline")
    print("=" * 50)
    
    # Step 1: Generate synthetic dataset
    print("\n1. Generating synthetic dental dataset...")
    generator = DentalDatasetGenerator(args.dataset_dir, args.num_images)
    generator.generate_dataset()
    dataset_yaml = generator.create_dataset_yaml()
    
    # Step 2: Train YOLO model
    print(f"\n2. Training YOLO model...")
    if not train_yolo_model(dataset_yaml, args.output_model, args.epochs, args.model_size):
        print("❌ Training failed. Exiting.")
        return 1
    
    # Step 3: Convert to CoreML
    print(f"\n3. Converting to CoreML...")
    if not convert_to_coreml(args.output_model, args.output_coreml):
        print("❌ CoreML conversion failed. Exiting.")
        return 1
    
    print(f"\n🎉 Training pipeline completed successfully!")
    print(f"📁 Dataset: {args.dataset_dir}")
    print(f"🤖 YOLO Model: {args.output_model}")
    print(f"📱 CoreML Model: {args.output_coreml}")
    print(f"\nNext steps:")
    print(f"1. Copy {args.output_coreml} to DentalAI/Resources/Models/")
    print(f"2. Build and run the iOS app")
    print(f"3. Test with real dental images")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())

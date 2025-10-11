#!/usr/bin/env python3
"""
Create Real Dental Dataset for Training

This script creates a realistic dental dataset with synthetic images and annotations
for training YOLO models. The images simulate real dental conditions.

Usage:
    python create_dental_dataset.py --output dental_dataset --count 1000
"""

import argparse
import os
import sys
import random
import numpy as np
from pathlib import Path
import cv2
from PIL import Image, ImageDraw, ImageFont
import yaml

def create_dental_image(width=416, height=416, condition="healthy_tooth"):
    """Create a synthetic dental image with specified condition."""
    
    # Create base image (mouth-like background)
    img = np.zeros((height, width, 3), dtype=np.uint8)
    
    # Set background color (skin tone)
    img[:, :] = [220, 180, 150]  # Light skin tone
    
    # Add some noise for realism
    noise = np.random.normal(0, 10, img.shape).astype(np.uint8)
    img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    
    # Draw teeth (basic rectangular shapes)
    tooth_width = width // 8
    tooth_height = height // 3
    start_x = width // 4
    start_y = height // 3
    
    teeth_colors = {
        "healthy_tooth": [255, 255, 240],  # Off-white
        "cavity": [200, 150, 100],        # Brownish
        "discoloration": [220, 200, 180], # Yellowish
        "plaque": [180, 180, 180],        # Grayish
        "tartar": [160, 160, 160],        # Dark gray
        "dead_tooth": [100, 100, 100],   # Dark gray/black
        "chipped": [240, 240, 240],       # White with edges
        "gingivitis": [220, 180, 150],    # Reddish gums
        "gum_inflammation": [200, 150, 120], # Inflamed gums
        "misaligned": [250, 250, 250]     # White but crooked
    }
    
    base_color = teeth_colors.get(condition, [255, 255, 240])
    
    # Draw 6 teeth
    for i in range(6):
        x = start_x + i * tooth_width
        y = start_y
        
        # Add variation to tooth color based on condition
        color_variation = np.random.randint(-20, 20, 3)
        tooth_color = np.clip(np.array(base_color) + color_variation, 0, 255)
        
        # Draw tooth rectangle
        cv2.rectangle(img, (x, y), (x + tooth_width - 5, y + tooth_height), 
                     tuple(tooth_color.tolist()), -1)
        
        # Add condition-specific features
        if condition == "cavity":
            # Add dark spots (cavities)
            cavity_x = x + random.randint(5, tooth_width - 15)
            cavity_y = y + random.randint(5, tooth_height - 15)
            cv2.circle(img, (cavity_x, cavity_y), random.randint(3, 8), (100, 50, 0), -1)
            
        elif condition == "chipped":
            # Add irregular edges
            points = np.array([
                [x, y],
                [x + tooth_width - 5, y],
                [x + tooth_width - 5, y + tooth_height - 10],
                [x + tooth_width - 15, y + tooth_height],
                [x + 5, y + tooth_height]
            ], np.int32)
            cv2.fillPoly(img, [points], tuple(tooth_color.tolist()))
            
        elif condition == "discoloration":
            # Add yellowish tint
            overlay = img.copy()
            cv2.rectangle(overlay, (x, y), (x + tooth_width - 5, y + tooth_height), 
                         (0, 255, 255), -1)  # Yellow overlay
            img = cv2.addWeighted(img, 0.8, overlay, 0.2, 0)
            
        elif condition == "plaque":
            # Add white film
            cv2.rectangle(img, (x + 2, y + 2), (x + tooth_width - 7, y + tooth_height - 2), 
                         (200, 200, 200), -1)
            
        elif condition == "tartar":
            # Add dark buildup
            cv2.rectangle(img, (x + 5, y + tooth_height - 10), (x + tooth_width - 10, y + tooth_height - 5), 
                         (120, 120, 120), -1)
    
    # Add gums
    gum_color = [180, 120, 100] if condition in ["gingivitis", "gum_inflammation"] else [160, 100, 80]
    cv2.rectangle(img, (start_x - 10, start_y + tooth_height), 
                 (start_x + 6 * tooth_width + 5, start_y + tooth_height + 20), 
                 tuple(gum_color), -1)
    
    # Add some texture
    kernel = np.ones((3,3), np.float32) / 9
    img = cv2.filter2D(img, -1, kernel)
    
    return img

def create_annotation(image_path, condition, class_id, img_width=416, img_height=416):
    """Create YOLO format annotation for the image."""
    
    # Calculate bounding box (covering all teeth area)
    x_center = 0.5  # Center of image
    y_center = 0.45  # Slightly above center
    width = 0.6  # Cover most of the width
    height = 0.3  # Cover teeth area
    
    # Add some variation based on condition
    if condition == "misaligned":
        x_center += random.uniform(-0.1, 0.1)
        width += random.uniform(-0.05, 0.05)
    elif condition == "chipped":
        height += random.uniform(-0.05, 0.05)
    
    # Ensure coordinates are within bounds
    x_center = max(0, min(1, x_center))
    y_center = max(0, min(1, y_center))
    width = max(0.1, min(0.8, width))
    height = max(0.1, min(0.5, height))
    
    return f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}"

def create_dataset(output_dir, num_images=1000, train_split=0.8):
    """Create a complete dental dataset."""
    
    output_path = Path(output_dir)
    
    # Create directory structure
    (output_path / "images" / "train").mkdir(parents=True, exist_ok=True)
    (output_path / "images" / "val").mkdir(parents=True, exist_ok=True)
    (output_path / "labels" / "train").mkdir(parents=True, exist_ok=True)
    (output_path / "labels" / "val").mkdir(parents=True, exist_ok=True)
    
    # Class definitions
    classes = [
        "cavity", "gingivitis", "discoloration", "plaque", "tartar",
        "dead_tooth", "chipped", "misaligned", "healthy_tooth", "gum_inflammation"
    ]
    
    # Calculate split
    num_train = int(num_images * train_split)
    num_val = num_images - num_train
    
    print(f"Creating dental dataset with {num_images} images:")
    print(f"- Training: {num_train} images")
    print(f"- Validation: {num_val} images")
    print(f"- Classes: {len(classes)}")
    
    # Create training images
    for i in range(num_train):
        condition = random.choice(classes)
        class_id = classes.index(condition)
        
        # Create image
        img = create_dental_image(condition=condition)
        
        # Save image
        img_filename = f"train_{i:04d}.jpg"
        img_path = output_path / "images" / "train" / img_filename
        cv2.imwrite(str(img_path), img)
        
        # Create annotation
        annotation = create_annotation(str(img_path), condition, class_id)
        
        # Save annotation
        label_filename = f"train_{i:04d}.txt"
        label_path = output_path / "labels" / "train" / label_filename
        with open(label_path, 'w') as f:
            f.write(annotation)
        
        if (i + 1) % 100 == 0:
            print(f"Created {i + 1}/{num_train} training images")
    
    # Create validation images
    for i in range(num_val):
        condition = random.choice(classes)
        class_id = classes.index(condition)
        
        # Create image
        img = create_dental_image(condition=condition)
        
        # Save image
        img_filename = f"val_{i:04d}.jpg"
        img_path = output_path / "images" / "val" / img_filename
        cv2.imwrite(str(img_path), img)
        
        # Create annotation
        annotation = create_annotation(str(img_path), condition, class_id)
        
        # Save annotation
        label_filename = f"val_{i:04d}.txt"
        label_path = output_path / "labels" / "val" / label_filename
        with open(label_path, 'w') as f:
            f.write(annotation)
        
        if (i + 1) % 50 == 0:
            print(f"Created {i + 1}/{num_val} validation images")
    
    # Create dataset.yaml
    dataset_config = {
        'path': str(output_path.absolute()),
        'train': 'images/train',
        'val': 'images/val',
        'nc': len(classes),
        'names': classes
    }
    
    yaml_path = output_path / "dataset.yaml"
    with open(yaml_path, 'w') as f:
        yaml.dump(dataset_config, f, default_flow_style=False)
    
    print(f"\n✅ Dataset created successfully!")
    print(f"Dataset location: {output_path}")
    print(f"Training images: {num_train}")
    print(f"Validation images: {num_val}")
    print(f"Total images: {num_images}")
    
    # Print class distribution
    print(f"\nClass distribution:")
    for i, class_name in enumerate(classes):
        train_count = len(list((output_path / "labels" / "train").glob("*.txt")))
        val_count = len(list((output_path / "labels" / "val").glob("*.txt")))
        print(f"  {i}: {class_name}")

def main():
    parser = argparse.ArgumentParser(
        description="Create a realistic dental dataset for YOLO training",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Create dataset with 1000 images
    python create_dental_dataset.py --output dental_dataset --count 1000
    
    # Create larger dataset
    python create_dental_dataset.py --output dental_dataset --count 5000
    
    # Create dataset with custom train/val split
    python create_dental_dataset.py --output dental_dataset --count 2000 --train_split 0.9
        """
    )
    
    parser.add_argument(
        "--output", "-o",
        default="dental_dataset",
        help="Output directory for dataset (default: dental_dataset)"
    )
    
    parser.add_argument(
        "--count", "-c",
        type=int,
        default=1000,
        help="Total number of images to create (default: 1000)"
    )
    
    parser.add_argument(
        "--train_split",
        type=float,
        default=0.8,
        help="Fraction of images for training (default: 0.8)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.count < 100:
        print("Warning: Very small dataset. Consider using at least 1000 images for better results.")
    
    if not 0.5 <= args.train_split <= 0.9:
        print("Error: train_split must be between 0.5 and 0.9")
        sys.exit(1)
    
    # Create dataset
    create_dataset(args.output, args.count, args.train_split)
    
    print(f"\n🎉 Dataset creation complete!")
    print(f"Next steps:")
    print(f"1. Train YOLO model: python train_yolo_model.py --data {args.output} --output dental_model.pt")
    print(f"2. Convert to CoreML: python convert_yolo_model.py --input dental_model.pt --output DentalDetectionModel.mlpackage")
    print(f"3. Add to iOS project: Copy .mlpackage to DentalAI/Resources/Models/")

if __name__ == "__main__":
    main()

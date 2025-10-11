#!/usr/bin/env python3
"""
Convert YOLO Model to CoreML for DentalAI iOS App

This script converts a trained YOLO model to CoreML format for use in the DentalAI iOS app.
The converted model can detect dental conditions on iOS devices.

Usage:
    python convert_yolo_model.py --input dental_model.pt --output DentalDetectionModel.mlpackage
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
    import coremltools as ct
    from ultralytics import YOLO
    import numpy as np
except ImportError as e:
    print(f"Error: Missing required packages. Please install:")
    print(f"pip install torch coremltools ultralytics")
    print(f"Original error: {e}")
    sys.exit(1)

def validate_yolo_model(model_path: str) -> bool:
    """Validate that the YOLO model file exists and is valid."""
    model_path = Path(model_path)
    
    if not model_path.exists():
        print(f"Error: Model file does not exist: {model_path}")
        return False
    
    if not model_path.suffix == '.pt':
        print(f"Error: Model file must be a .pt file: {model_path}")
        return False
    
    try:
        # Try to load the model
        model = YOLO(str(model_path))
        print(f"✅ YOLO model validation passed: {model_path}")
        return True
    except Exception as e:
        print(f"❌ Failed to load YOLO model: {e}")
        return False

def convert_yolo_to_coreml(input_path: str, output_path: str, input_size: int = 416, confidence: float = 0.5, iou: float = 0.45, quantize: bool = False):
    """Convert YOLO model to CoreML format."""
    
    print(f"Converting YOLO model to CoreML...")
    print(f"Input: {input_path}")
    print(f"Output: {output_path}")
    print(f"Input size: {input_size}x{input_size}")
    print(f"Confidence threshold: {confidence}")
    print(f"IoU threshold: {iou}")
    print(f"Quantization: {'Enabled' if quantize else 'Disabled'}")
    
    try:
        # Load YOLO model
        print("\n1. Loading YOLO model...")
        model = YOLO(input_path)
        
        # Export to CoreML
        print("\n2. Exporting to CoreML...")
        coreml_model = model.export(
            format='coreml',
            imgsz=input_size,
            conf=confidence,
            iou=iou,
            optimize=True,
            half=False,  # Use full precision for better accuracy
            int8=quantize,  # Enable quantization if requested
            dynamic=False,  # Static input size for better performance
            simplify=True,  # Simplify the model
            opset=None,  # Use default opset
            workspace=4,  # Workspace size in GB
            nms=True,  # Include NMS in the model
            agnostic_nms=False,  # Class-aware NMS
            retina_masks=False,  # No mask support
            format='coreml'
        )
        
        print(f"\n3. Saving CoreML model...")
        # Save the CoreML model
        coreml_model.save(output_path)
        
        print(f"\n✅ CoreML conversion successful!")
        print(f"Model saved to: {output_path}")
        
        # Calculate model size
        model_size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"- Model size: {model_size_mb:.2f} MB")
        
        # Print model information
        print(f"\nModel Information:")
        print(f"- Input size: {input_size}x{input_size}")
        print(f"- Confidence threshold: {confidence}")
        print(f"- IoU threshold: {iou}")
        print(f"- Quantization: {'Enabled' if quantize else 'Disabled'}")
        
        # Print supported classes
        classes = [
            "cavity", "gingivitis", "discoloration", "plaque", "tartar",
            "dead_tooth", "chipped", "misaligned", "healthy_tooth", "gum_inflammation"
        ]
        print(f"- Supported classes: {len(classes)}")
        for i, class_name in enumerate(classes):
            print(f"  {i}: {class_name}")
        
        return True
        
    except Exception as e:
        print(f"\n❌ CoreML conversion failed: {str(e)}")
        return False

def create_sample_coreml_model(output_path: str, input_size: int = 416):
    """Create a sample CoreML model for testing (no YOLO conversion)."""
    
    print(f"Creating sample CoreML model...")
    print(f"Output: {output_path}")
    print(f"Input size: {input_size}x{input_size}")
    
    try:
        # Create a simple CoreML model for testing
        from coremltools.models import MLModel
        from coremltools.models.neural_network import NeuralNetworkBuilder
        from coremltools.models.datatypes import Array, Float
        
        # Create input specification
        input_spec = [
            ('image', Array(3, input_size, input_size, Float))
        ]
        
        # Create output specification
        output_spec = [
            ('detections', Array(25200, 15, Float))  # YOLO output format
        ]
        
        # Create builder
        builder = NeuralNetworkBuilder(input_spec, output_spec)
        
        # Add a simple identity layer (placeholder)
        builder.add_activation('identity', 'LINEAR', input_name='image', output_name='detections')
        
        # Create model
        model = MLModel(builder.spec)
        
        # Add metadata
        model.short_description = "DentalAI Detection Model (Sample)"
        model.author = "DentalAI Team"
        model.license = "MIT"
        model.version = "1.0"
        
        # Save model
        model.save(output_path)
        
        print(f"\n✅ Sample CoreML model created successfully!")
        print(f"Model saved to: {output_path}")
        
        # Calculate model size
        model_size_mb = os.path.getsize(output_path) / (1024 * 1024)
        print(f"- Model size: {model_size_mb:.2f} MB")
        print(f"- Note: This is a sample model, not a trained YOLO model")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Sample model creation failed: {str(e)}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description="Convert YOLO model to CoreML format for DentalAI iOS app",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Convert trained YOLO model to CoreML
    python convert_yolo_model.py --input dental_model.pt --output DentalDetectionModel.mlpackage
    
    # Convert with custom parameters
    python convert_yolo_model.py --input dental_model.pt --output DentalDetectionModel.mlpackage --input_size 320 --confidence 0.7
    
    # Convert with quantization for smaller size
    python convert_yolo_model.py --input dental_model.pt --output DentalDetectionModel.mlpackage --quantize
    
    # Create sample model for testing
    python convert_yolo_model.py --output DentalDetectionModel.mlpackage --sample
        """
    )
    
    parser.add_argument(
        "--input", "-i",
        help="Path to input YOLO model (.pt file)"
    )
    
    parser.add_argument(
        "--output", "-o",
        required=True,
        help="Path to output CoreML model (.mlpackage file)"
    )
    
    parser.add_argument(
        "--input_size",
        type=int,
        default=416,
        help="Input image size (default: 416)"
    )
    
    parser.add_argument(
        "--confidence",
        type=float,
        default=0.5,
        help="Confidence threshold (default: 0.5)"
    )
    
    parser.add_argument(
        "--iou",
        type=float,
        default=0.45,
        help="IoU threshold for NMS (default: 0.45)"
    )
    
    parser.add_argument(
        "--quantize",
        action="store_true",
        help="Enable quantization for smaller model size"
    )
    
    parser.add_argument(
        "--sample",
        action="store_true",
        help="Create a sample CoreML model for testing (no YOLO conversion)"
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.sample and not args.input:
        print("Error: Either --input or --sample must be specified")
        print("Use --input to convert a YOLO model")
        print("Use --sample to create a sample model for testing")
        sys.exit(1)
    
    # Create output directory if it doesn't exist
    output_dir = os.path.dirname(args.output)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
        print(f"Created output directory: {output_dir}")
    
    # Convert model
    if args.sample:
        success = create_sample_coreml_model(args.output, args.input_size)
    else:
        # Validate input model
        if not validate_yolo_model(args.input):
            sys.exit(1)
        
        success = convert_yolo_to_coreml(
            args.input, 
            args.output, 
            args.input_size, 
            args.confidence, 
            args.iou, 
            args.quantize
        )
    
    if success:
        print(f"\n🎉 CoreML model created successfully!")
        print(f"Next steps:")
        print(f"1. Copy {args.output} to DentalAI/Resources/Models/")
        print(f"2. Update model name in MLDetectionService.swift")
        print(f"3. Build and test the iOS app")
        print(f"4. Test detection with real dental images")
    else:
        print(f"\n💥 CoreML conversion failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
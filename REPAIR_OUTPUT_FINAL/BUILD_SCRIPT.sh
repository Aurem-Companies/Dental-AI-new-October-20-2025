#!/usr/bin/env bash
set -euo pipefail

echo "🧹 Cleaning derived data for consistent build..."
rm -rf ~/Library/Developer/Xcode/DerivedData

echo "🔧 Building DentalAI project..."

# Build using workspace (preferred for complex projects)
if [ -d "./DentalAI.xcworkspace" ] || [ -f "./DentalAI.xcworkspace" ]; then
  echo "📦 Building with workspace..."
  xcodebuild -workspace "DentalAI.xcworkspace" -scheme "DentalAI" -destination 'generic/platform=iOS Simulator' clean build
else
  echo "📦 Building with project..."
  xcodebuild -project "DentalAI.xcodeproj" -scheme "DentalAI" -destination 'generic/platform=iOS Simulator' clean build
fi

echo "✅ Build finished successfully!"

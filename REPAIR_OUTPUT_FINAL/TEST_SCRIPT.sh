#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Running DentalAI UI Tests..."

# Check if workspace exists, otherwise use project
if [ -d "./DentalAI.xcworkspace" ] || [ -f "./DentalAI.xcworkspace" ]; then
  echo "📦 Running tests with workspace..."
  xcodebuild test \
    -workspace "DentalAI.xcworkspace" \
    -scheme "DentalAI" \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    | tee test.out
else
  echo "📦 Running tests with project..."
  xcodebuild test \
    -project "DentalAI.xcodeproj" \
    -scheme "DentalAI" \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    | tee test.out
fi

echo "✅ UI Tests completed!"
echo "📄 Test results saved to test.out"

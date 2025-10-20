#!/bin/bash
set -euo pipefail

# CI Model Validation Script
# Fails the build if the compiled CoreML model is missing

MODEL_NAME="DentalModel"   # Set correctly
SEARCH_SUBDIR="models"             # or "" if at root

echo "🔍 Checking for compiled CoreML model..."

# Determine the app bundle path
if [ -n "${BUILT_PRODUCTS_DIR:-}" ] && [ -n "${WRAPPER_NAME:-}" ]; then
    # Running in Xcode build
    APP_BUNDLE="${BUILT_PRODUCTS_DIR}/${WRAPPER_NAME}"
else
    # Running standalone or CI
    APP_BUNDLE="${1:-DentalAI.app}"
fi

if [ -n "$SEARCH_SUBDIR" ]; then
    MODEL_PATH="${APP_BUNDLE}/${SEARCH_SUBDIR}/${MODEL_NAME}.mlmodelc"
else
    MODEL_PATH="${APP_BUNDLE}/${MODEL_NAME}.mlmodelc"
fi

echo "📁 Checking: $MODEL_PATH"

if [ ! -d "$MODEL_PATH" ]; then
    echo "❌ Compiled model not found at: $MODEL_PATH"
    echo "💡 Make sure:"
    echo "   1. Your .mlmodel file is added to the target"
    echo "   2. It's in 'Copy Bundle Resources'"
    echo "   3. The compiled name matches '$MODEL_NAME'"
    echo "   4. It's placed in the '$SEARCH_SUBDIR' subdirectory"
    exit 1
fi

echo "✅ Found compiled model at: $MODEL_PATH"
echo "📊 Model size: $(du -sh "$MODEL_PATH" | cut -f1)"

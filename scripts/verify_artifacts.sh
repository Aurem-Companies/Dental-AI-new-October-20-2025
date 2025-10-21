#!/bin/bash
set -euo pipefail
CONFIG="${CONFIGURATION:-Release}"
if [[ "$CONFIG" == "Release" ]]; then
  if /usr/libexec/PlistBuddy -c "Print :useMLDetection" "$SRCROOT/DerivedFlags.plist" 2>/dev/null | grep -q "true"; then
    if ! /usr/bin/find "$BUILT_PRODUCTS_DIR/$CONTENTS_FOLDER_PATH" -name "*.mlmodelc" -maxdepth 3 | grep -q .; then
      echo "ERROR: useMLDetection=true but no .mlmodelc in app bundle."
      exit 1
    fi
  fi
fi

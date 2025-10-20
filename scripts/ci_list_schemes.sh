#!/usr/bin/env bash
set -euo pipefail
echo "== Project Schemes =="
xcodebuild -list -project DentalAI.xcodeproj || true
if [ -e "DentalAI.xcworkspace" ]; then
  echo "== Workspace Schemes =="
  xcodebuild -list -workspace DentalAI.xcworkspace || true
fi

#!/usr/bin/env swift

// Simple compilation test for DentalAI project
// This script tests that all the new files can be imported and compiled

import Foundation

print("Testing DentalAI compilation...")

// Test that we can reference the main types
let _ = Detection(label: "test", confidence: 0.5, boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100))
let _ = ModelError.modelUnavailable
let _ = FeatureFlags.useMLDetection

print("✅ Basic types can be referenced")

// Test feature flags
FeatureFlags.configureDefaults()
print("✅ Feature flags configured")

// Test detection factory
let service = DetectionFactory.make()
print("✅ Detection factory created service: \(type(of: service))")

print("🎉 All compilation tests passed!")

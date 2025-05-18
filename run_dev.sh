#!/bin/bash

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Clean any previous builds
echo "Cleaning previous build artifacts..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate code if needed
echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app in debug mode with verbose logging
echo "Starting app in debug mode..."
flutter run --verbose 
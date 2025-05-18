#!/bin/bash

# Ensure we're in the right directory
cd "$(dirname "$0")"

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate code if needed
echo "Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app on Android
echo "Starting app on Android..."
flutter run -d android 
#!/bin/bash
# Run app without Firebase

# Run flutter with alternative main file
cd ..
echo "Running Flutter without Firebase..."
flutter run --no-fast-start -t lib/main_no_firebase.dart

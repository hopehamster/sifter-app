#!/bin/bash
# Binary patching approach

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Add build phase
ruby add_build_phase.rb

# Check the current directory structure for debugging
echo "iOS directory structure:"
ls -la

# Run Flutter with release mode to avoid using debug symbols
cd ..
echo "Building iOS app in release mode..."
flutter build ios --release
echo "Running app in release mode..."
flutter run --release

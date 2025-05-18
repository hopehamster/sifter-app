#!/bin/bash
# Run app with tgmath.h fix applied

# Set up environment variables
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export HEADER_SEARCH_PATHS="$(pwd)/wrappers/usr/include"
export C_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$CPLUS_INCLUDE_PATH"

# Make sure Flutter is up to date
cd ..
flutter clean
flutter pub get
cd ios

# Update CocoaPods repositories
echo "Updating CocoaPods repositories..."
pod repo update

# Install pods with our wrapper
echo "Installing pods..."
pod install --repo-update

# Patch source files to fix format attribute issues
./patch_boringssl_source.sh

# Run flutter in debug mode
cd ..
echo "Running Flutter with all fixes applied..."
flutter run

#!/bin/bash
# Run Flutter with binary patching for BoringSSL-GRPC

# Set up environment variables to help with build
export OTHER_CFLAGS="-w -Wno-format -Wno-everything"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

# Add our bin directory to the path so our xcodebuild wrapper is used
export PATH="$(pwd)/bin:$PATH"

# Check for Ruby and Xcodeproj gem for the build phase script
if ! command -v ruby &> /dev/null; then
  echo "Error: Ruby is required but not installed"
  exit 1
fi

if ! ruby -e "require 'xcodeproj'" &> /dev/null; then
  echo "Installing xcodeproj gem..."
  gem install xcodeproj
fi

# Add our build phase to the Xcode project
echo "Adding build phase to Xcode project..."
ruby add_build_phase.rb

echo "Running Flutter with binary patching..."
cd ..
flutter run

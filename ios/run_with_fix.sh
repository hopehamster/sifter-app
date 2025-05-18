#!/bin/bash
# Run Flutter app with BoringSSL-GRPC fix applied

# Set environment variables to prevent -G flag issue
export OTHER_CFLAGS="-w"
export OTHER_CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export PATH="$(pwd)/bin:$PATH"

# Run flutter in parent directory
cd ..
flutter run

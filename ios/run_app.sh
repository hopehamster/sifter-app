#!/bin/bash
# Script to run Flutter app with BoringSSL-GRPC fix applied

# Set environment variables
export OTHER_CFLAGS="-w"
export OTHER_CXXFLAGS="-w"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export PATH="$(pwd)/bin:$PATH"

cd ..
flutter run

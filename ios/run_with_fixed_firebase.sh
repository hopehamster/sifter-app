#!/bin/bash
# Run app with all firebase version and BoringSSL fixes applied

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Apply source patches
./patch_boringssl.sh

# Run Flutter
cd ..
flutter run

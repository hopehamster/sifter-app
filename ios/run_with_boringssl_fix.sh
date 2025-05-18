#!/bin/bash
# Run Flutter with BoringSSL fix applied

# Banner
echo "======================================================================"
echo "            RUNNING FLUTTER WITH BORINGSSL-GRPC FIX APPLIED           "
echo "======================================================================"

# Set environment variables to prevent -G flag issue
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"

# Display environment info
echo "PATH includes wrapper at: $(pwd)/bin"
echo "Compiler: $(which clang)"
echo "Environment variables set successfully"

# Run flutter from parent directory
cd ..
echo "Running Flutter..."
flutter run

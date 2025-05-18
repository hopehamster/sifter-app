#!/bin/bash
# Enable wrapper debugging and run app

# Set the debug flag for the wrapper
export DEBUG_WRAPPER=1

# Run the fix
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Clear previous log
rm -f /tmp/clang_wrapper.log

echo "Starting with debugging enabled. Log will be at /tmp/clang_wrapper.log"
cd ..
flutter run

echo "Build complete. Check wrapper log at /tmp/clang_wrapper.log"

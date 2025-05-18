#!/bin/bash
# Open Xcode with all environment variables set correctly

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export DEBUG="NO"

# Open Xcode
open Runner.xcworkspace

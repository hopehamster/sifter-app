#!/bin/bash
# Launch Xcode with our patched environment
# This sets up the PATH to use our clang wrapper

# Export our bin directory in the PATH
export PATH="$(pwd)/bin:$PATH"

# Additional environment variables to help with the build
export COMPILER_INDEX_STORE_ENABLE=NO
export GCC_WARN_INHIBIT_ALL_WARNINGS=YES

# Launch Xcode
open Runner.xcworkspace

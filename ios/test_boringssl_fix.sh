#!/bin/bash

# Script to test if the BoringSSL-GRPC fix was successful
# This script analyzes the build process and looks for specific issues

echo "=== BoringSSL-GRPC Fix Verification Tool ==="
echo "This script will check if the fixes have been properly applied"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Function to check if a file contains a pattern
check_file_for_pattern() {
  local file="$1"
  local pattern="$2"
  local description="$3"
  
  if [ ! -f "$file" ]; then
    echo -e "${YELLOW}[WARN]${NC} File $file does not exist, skipping check"
    return 1
  fi
  
  if grep -q "$pattern" "$file"; then
    echo -e "${RED}[FAIL]${NC} $description: Pattern found in $file"
    grep -n "$pattern" "$file"
    return 1
  else
    echo -e "${GREEN}[PASS]${NC} $description: No problematic pattern in $file"
    return 0
  fi
}

# Function to check if a command output contains a pattern
check_command_for_pattern() {
  local cmd="$1"
  local pattern="$2"
  local description="$3"
  
  echo "Running command: $cmd"
  local output
  output=$(eval "$cmd" 2>&1)
  
  if echo "$output" | grep -q "$pattern"; then
    echo -e "${RED}[FAIL]${NC} $description: Pattern found in command output"
    echo "$output" | grep -n "$pattern"
    return 1
  else
    echo -e "${GREEN}[PASS]${NC} $description: No problematic pattern in command output"
    return 0
  fi
}

# Check if we're in the ios directory
if [ ! -d "Pods" ]; then
  echo -e "${YELLOW}[WARN]${NC} This script should be run from the ios directory"
  if [ -d "ios" ]; then
    echo "Changing to ios directory..."
    cd ios || exit 1
  else
    echo -e "${RED}[FAIL]${NC} Could not find ios directory"
    exit 1
  fi
fi

# Find BoringSSL-GRPC directory
BORINGSSL_DIR=$(find Pods -type d -name "BoringSSL-GRPC" -print -quit 2>/dev/null)
if [ -z "$BORINGSSL_DIR" ]; then
  echo -e "${RED}[FAIL]${NC} BoringSSL-GRPC directory not found. Have you run pod install?"
  exit 1
fi

echo "Found BoringSSL-GRPC at: $BORINGSSL_DIR"

# Check 1: Verify xcconfig files have been patched
echo -e "\n=== Checking xcconfig files ==="
XCCONFIG_FILES=$(find "Pods/Target Support Files/BoringSSL-GRPC" -name "*.xcconfig" 2>/dev/null)
if [ -z "$XCCONFIG_FILES" ]; then
  echo -e "${YELLOW}[WARN]${NC} No xcconfig files found for BoringSSL-GRPC"
else
  for file in $XCCONFIG_FILES; do
    check_file_for_pattern "$file" "-G" "Checking for -G flag in xcconfig"
    check_file_for_pattern "$file" "GCC_WARN_INHIBIT_ALL_WARNINGS = NO" "Checking for proper warning setting"
  done
fi

# Check 2: Verify source files have been patched
echo -e "\n=== Checking source files ==="
BASE_H="$BORINGSSL_DIR/src/include/openssl/base.h"
if [ -f "$BASE_H" ]; then
  check_file_for_pattern "$BASE_H" "__attribute__.*format.*printf" "Checking for format attribute in base.h"
  
  # Check if our patch header is included
  if grep -q "boringssl_build_fix.h" "$BASE_H"; then
    echo -e "${GREEN}[PASS]${NC} Our patch header is included in base.h"
  else
    echo -e "${YELLOW}[WARN]${NC} Our patch header is not included in base.h"
  fi
else
  echo -e "${YELLOW}[WARN]${NC} File base.h not found at expected location"
fi

# Check 3: Verify the build phase has been added
echo -e "\n=== Checking Xcode build phase ==="
if [ -f "Runner.xcodeproj/project.pbxproj" ]; then
  if grep -q "BoringSSL-GRPC Fix" "Runner.xcodeproj/project.pbxproj"; then
    echo -e "${GREEN}[PASS]${NC} Found build phase in Xcode project"
  else
    echo -e "${YELLOW}[WARN]${NC} Build phase not found in Xcode project"
    echo "You may need to run: ruby add_build_phase.rb"
  fi
else
  echo -e "${YELLOW}[WARN]${NC} Xcode project file not found"
fi

# Check 4: Attempt to simulate a compile command
echo -e "\n=== Simulating compile command ==="
ORIG_CC="$(xcrun -f clang)"
if [ -f "clang_wrapper.sh" ]; then
  # Use our wrapper
  CC="./clang_wrapper.sh"
  echo "Using our clang wrapper to test compilation"
else
  # Use the system compiler
  CC="$ORIG_CC"
  echo "Using system clang to test compilation"
fi

# Create a temporary file with a problematic format attribute
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << EOL
#include <stdio.h>

__attribute__((__format__(__printf__, 1, 2)))
void test_function(const char *format, ...);

int main() {
    return 0;
}
EOL

# Try compiling it
echo "Testing compilation of a file with format attribute..."
RESULT=$(DEBUG=1 $CC -c "$TEMP_FILE" -o /dev/null 2>&1 || true)

# Check for the -G flag in the compilation command
if echo "$RESULT" | grep -q "\-G"; then
  if echo "$RESULT" | grep -q "REMOVED: -G"; then
    echo -e "${GREEN}[PASS]${NC} Our clang wrapper successfully removed the -G flag"
  else
    echo -e "${RED}[FAIL]${NC} The -G flag is still present in the compilation command"
    echo "$RESULT" | grep -n "\-G"
  fi
else
  echo -e "${GREEN}[PASS]${NC} No -G flag found in the compilation command"
fi

# Clean up
rm -f "$TEMP_FILE"

# Final verification: Check for any remaining -G flags in the CocoaPods project
echo -e "\n=== Checking for remaining -G flags in CocoaPods project ==="
if find "Pods" -type f -name "project.pbxproj" -exec grep -l "\-G" {} \; | grep -q .; then
  echo -e "${RED}[FAIL]${NC} Found -G flags in project files:"
  find "Pods" -type f -name "project.pbxproj" -exec grep -l "\-G" {} \;
  echo "You may need to manually edit these files or run the patch_source_files.sh script"
else
  echo -e "${GREEN}[PASS]${NC} No -G flags found in project files"
fi

echo -e "\n=== Test Completion ==="
echo "If you see any FAIL messages, some fixes may not have been correctly applied."
echo "Try running fix_boringssl_and_rebuild.sh again, or refer to BORINGSSL_FIX_README.md"
echo "for manual steps."

# Final recommendation
if [ -f "fix_boringssl_and_rebuild.sh" ]; then
  echo -e "\nMost complete fix: ${GREEN}./fix_boringssl_and_rebuild.sh${NC}"
else
  echo -e "${YELLOW}[WARN]${NC} fix_boringssl_and_rebuild.sh not found - this is the most complete fix script"
  echo "Visit https://github.com/FirebaseExtended/flutterfire/issues/9338 for more information"
fi 
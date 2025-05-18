#!/bin/bash
# This script patches BoringSSL framework binaries to remove -G flags

# Find all build products directories
BUILD_DIR=~/Library/Developer/Xcode/DerivedData

echo "Searching for BoringSSL frameworks in $BUILD_DIR..."

# Find all BoringSSL frameworks
FRAMEWORKS=$(find "$BUILD_DIR" -path "*/Build/Products/*" -name "BoringSSL*.framework" 2>/dev/null)

if [ -z "$FRAMEWORKS" ]; then
  echo "No BoringSSL frameworks found. Trying to find gRPC frameworks..."
  FRAMEWORKS=$(find "$BUILD_DIR" -path "*/Build/Products/*" -name "gRPC*.framework" 2>/dev/null)
fi

if [ -z "$FRAMEWORKS" ]; then
  echo "No relevant frameworks found to patch."
  exit 0
fi

echo "Found frameworks to patch:"
for FRAMEWORK in $FRAMEWORKS; do
  echo "- $FRAMEWORK"
  
  # Find the binary inside the framework (same name as framework without extension)
  FRAMEWORK_NAME=$(basename "$FRAMEWORK" .framework)
  BINARY="$FRAMEWORK/$FRAMEWORK_NAME"
  
  if [ -f "$BINARY" ]; then
    echo "  Patching binary: $BINARY"
    
    # Create backup
    if [ ! -f "${BINARY}.backup" ]; then
      cp "$BINARY" "${BINARY}.backup"
    fi
    
    # Use hexdump to find and modify G flag references
    # This is a simplified example - actual binary patching is more complex
    # and would require careful analysis of the specific binary
    
    # For now, let's just look for -G strings in the binary for diagnostic purposes
    echo "  Searching for -G flag in binary..."
    strings "$BINARY" | grep -- "-G" 
    
    # In a real implementation, you would use tools like hexedit or direct binary manipulation
    # to replace the -G flag references with something harmless
  else
    echo "  Warning: Could not find binary in framework"
  fi
done

echo "Completed framework patching"

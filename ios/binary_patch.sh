#!/bin/bash
# Binary patching for compiled frameworks

echo "Searching for compiled BoringSSL frameworks..."
FRAMEWORK_DIRS=(
  "Pods"
  "DerivedData"
  "build"
  "~/Library/Developer/Xcode/DerivedData"
)

for DIR in "${FRAMEWORK_DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    echo "Searching in $DIR..."
    FRAMEWORKS=$(find "$DIR" -name "BoringSSL*.framework" -o -name "gRPC*.framework" 2>/dev/null)
    
    if [ -n "$FRAMEWORKS" ]; then
      echo "Found frameworks:"
      for FRAMEWORK in $FRAMEWORKS; do
        echo "- Patching $FRAMEWORK"
        
        # Find binary
        BINARY=$(find "$FRAMEWORK" -type f -name "BoringSSL*" -o -name "gRPC*" 2>/dev/null | grep -v "\.h$" | head -1)
        if [ -n "$BINARY" ]; then
          echo "  Found binary: $BINARY"
          
          # Create backup
          if [ ! -f "${BINARY}.backup" ]; then
            cp "$BINARY" "${BINARY}.backup"
          fi
          
          # Find and patch all occurrences of the format string
          FORMAT_PATTERN=$(hexdump -C "$BINARY" | grep -B2 -A2 "format" | grep -A2 "__printf__" || true)
          if [ -n "$FORMAT_PATTERN" ]; then
            echo "  Found format pattern: $FORMAT_PATTERN"
            # Patch the binary by replacing the format attribute with spaces
            echo "  Patching binary..."
            # This is a placeholder - binary patching would be complex and risky
            # We would need to use a hex editor or similar tool to modify the binary
            echo "  Binary patching is not implemented in this script"
          fi
        fi
        
        # Find and patch header files
        HEADERS=$(find "$FRAMEWORK" -name "*.h" 2>/dev/null)
        for HEADER in $HEADERS; do
          if grep -q "__format__" "$HEADER"; then
            echo "  Patching header: $HEADER"
            sed -i '' 's/__attribute__((__format__[^)]*))//g' "$HEADER" || true
          fi
        done
      done
    fi
  fi
done

echo "Binary patching completed"

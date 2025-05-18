#!/bin/bash
# Xcode build phase script to patch binaries

echo "Running BoringSSL-GRPC fix in build phase..."

# Look for BoringSSL frameworks
FRAMEWORKS=$(find "${BUILT_PRODUCTS_DIR}" -name "BoringSSL*.framework" 2>/dev/null)
if [ -z "$FRAMEWORKS" ]; then
  FRAMEWORKS=$(find "${BUILT_PRODUCTS_DIR}" -name "gRPC*.framework" 2>/dev/null)
fi

if [ -n "$FRAMEWORKS" ]; then
  echo "Found BoringSSL or gRPC frameworks:"
  for FRAMEWORK in $FRAMEWORKS; do
    echo "- $FRAMEWORK"
    
    # Find header files with format attributes
    HEADERS=$(find "$FRAMEWORK" -name "*.h" 2>/dev/null)
    for HEADER in $HEADERS; do
      if grep -q "__format__" "$HEADER"; then
        echo "  Patching header: $HEADER"
        sed -i '' 's/__attribute__((__format__[^)]*))//g' "$HEADER"
      fi
    done
  done
  echo "Completed patching frameworks"
fi

exit 0

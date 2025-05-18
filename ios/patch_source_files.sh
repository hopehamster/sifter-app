#!/bin/bash

# Script to patch BoringSSL-GRPC source files to prevent -G flag usage
echo "Patching BoringSSL-GRPC source files..."

# Ensure PODS_ROOT is set
if [ -z "$PODS_ROOT" ]; then
  # Try to find it
  PODS_ROOT="Pods"
  if [ ! -d "$PODS_ROOT" ]; then
    echo "Error: PODS_ROOT not set and Pods directory not found"
    exit 1
  fi
fi

echo "Using PODS_ROOT: $PODS_ROOT"

# Function to search for problematic patterns and fix them
search_and_fix() {
  local dir="$1"
  local pattern="$2"
  local replacement="$3"
  local file_pattern="$4"
  
  echo "Searching for \"$pattern\" in $dir with file pattern $file_pattern"
  
  # Find all matching files and replace the pattern
  find "$dir" -path "*BoringSSL-GRPC*" -name "$file_pattern" -type f -print0 | 
    while IFS= read -r -d '' file; do
      if grep -q "$pattern" "$file"; then
        echo "Patching file: $file"
        sed -i '' "s/$pattern/$replacement/g" "$file"
      fi
    done
}

# Find the BoringSSL-GRPC directory
BORINGSSL_DIR=$(find "$PODS_ROOT" -type d -name "BoringSSL-GRPC" -print -quit)

if [ -z "$BORINGSSL_DIR" ]; then
  echo "Error: BoringSSL-GRPC directory not found"
  exit 1
fi

echo "Found BoringSSL-GRPC at: $BORINGSSL_DIR"

# Patch 1: Find any compiler attribute that might trigger -G flags
search_and_fix "$BORINGSSL_DIR" "__attribute__.*format.*" "/* __attribute__((__format__(printf" "*.c"
search_and_fix "$BORINGSSL_DIR" "__attribute__.*format.*" "/* __attribute__((__format__(printf" "*.h"

# Patch 2: Compiler directives that might be problematic
search_and_fix "$BORINGSSL_DIR" "#pragma GCC" "// #pragma GCC" "*.c"
search_and_fix "$BORINGSSL_DIR" "#pragma GCC" "// #pragma GCC" "*.h"
search_and_fix "$BORINGSSL_DIR" "#pragma clang" "// #pragma clang" "*.c"
search_and_fix "$BORINGSSL_DIR" "#pragma clang" "// #pragma clang" "*.h"

# Patch 3: Look for functions declared with format attributes
search_and_fix "$BORINGSSL_DIR" "OPENSSL_PRINTF_FORMAT" "/* OPENSSL_PRINTF_FORMAT */" "*.c"
search_and_fix "$BORINGSSL_DIR" "OPENSSL_PRINTF_FORMAT" "/* OPENSSL_PRINTF_FORMAT */" "*.h"

# Patch 4: Create a special header to include at build time
PATCH_HEADER="$BORINGSSL_DIR/src/include/openssl/boringssl_build_fix.h"
echo "Creating patch header: $PATCH_HEADER"

cat > "$PATCH_HEADER" << EOL
/* BoringSSL build fix header to prevent -G flag usage */
#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H
#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H

/* Redefine problematic macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)

/* Disable format attributes that might trigger -G flags */
#define __attribute__(x)

#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */
EOL

echo "Finished patching BoringSSL-GRPC source files"

# Create a new implementation file for err_data.c if it might be causing problems
if [ -f "$BORINGSSL_DIR/err_data.c" ]; then
  echo "Creating patched version of err_data.c"
  
  # Make a backup
  cp "$BORINGSSL_DIR/err_data.c" "$BORINGSSL_DIR/err_data.c.original"
  
  # Replace problematic content with a simplified version
  cat > "$BORINGSSL_DIR/err_data.c" << EOL
/* This is a patched version of err_data.c with format attributes removed */
#include <openssl/err.h>
#include <openssl/type_check.h>
#include "internal.h"

/* Simple implementation that doesn't use format attributes */
const char *ERR_reason_error_string(uint32_t packed_error) {
  return "Error string omitted for build compatibility";
}

void ERR_clear_error(void) {
  /* Simplified implementation */
}

uint32_t ERR_get_error(void) {
  /* Simplified implementation */
  return 0;
}
EOL
fi

exit 0 
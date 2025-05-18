#!/bin/bash
# Aggressive wrapper script for clang to remove -G flags and modify compilation

# Log file for debugging
WRAPPER_LOG="/tmp/clang_wrapper.log"
echo "=============== $(date) ===============" >> "$WRAPPER_LOG"
echo "Args: $@" >> "$WRAPPER_LOG"

# Get the real clang binary
REAL_CLANG="$(xcrun -f clang)"
echo "Real clang: $REAL_CLANG" >> "$WRAPPER_LOG"

# Create filtered arguments
ARGS=()
for arg in "$@"; do
  # Skip any arguments with -G
  if [[ "$arg" != -G* ]]; then
    ARGS+=("$arg")
  else
    echo "Filtered out: $arg" >> "$WRAPPER_LOG"
  fi
done

# Check if we're compiling BoringSSL or gRPC files
IS_BORING_SSL=0
for arg in "$@"; do
  if [[ "$arg" == *"BoringSSL"* || "$arg" == *"boringssl"* || "$arg" == *"grpc"* || "$arg" == *"gRPC"* ]]; then
    IS_BORING_SSL=1
    echo "Detected BoringSSL/gRPC file" >> "$WRAPPER_LOG"
    break
  fi
done

# Add special flags for BoringSSL compilations
if [ $IS_BORING_SSL -eq 1 ]; then
  # Add preprocessor definitions to disable problematic features
  ARGS+=("-DOPENSSL_NO_ASM=1")
  ARGS+=("-D__attribute__(x)=")
  ARGS+=("-DOPENSSL_PRINTF_FORMAT(a,b)=")
  ARGS+=("-DOPENSSL_PRINTF_FORMAT_FUNC(a,b)=")
  
  # Add warning suppression flags
  ARGS+=("-w")
  ARGS+=("-Wno-format")
  ARGS+=("-Wno-format-security")
  ARGS+=("-Wno-everything")
  
  echo "Added BoringSSL-specific flags" >> "$WRAPPER_LOG"
fi

# Log the final command
echo "Running: $REAL_CLANG ${ARGS[@]}" >> "$WRAPPER_LOG"

# Execute the real compiler with our modified arguments
"$REAL_CLANG" "${ARGS[@]}"
EXIT_CODE=$?

# Log the result
echo "Exit code: $EXIT_CODE" >> "$WRAPPER_LOG"
exit $EXIT_CODE

#!/bin/bash

# Wrapper script for clang to filter out -G flags
# Place this in your iOS project directory and set CC=path/to/clang_wrapper.sh

# Log execution details if DEBUG is set
if [ -n "$DEBUG" ]; then
  echo "clang_wrapper.sh invoked with args: $*" >&2
fi

# Get the original clang compiler
REAL_CLANG="$(xcrun -f clang)"

# Temporary file for filtered arguments
FILTERED_ARGS_FILE=$(mktemp)

# Process all arguments and filter out -G flags
for arg in "$@"; do
  if [[ "$arg" != -G* ]]; then
    echo "$arg" >> "$FILTERED_ARGS_FILE"
  else
    echo "REMOVED: $arg" >&2
  fi
done

# Read arguments from file to handle spaces and special characters
FILTERED_ARGS=()
while IFS= read -r line; do
  FILTERED_ARGS+=("$line")
done < "$FILTERED_ARGS_FILE"

# Clean up
rm "$FILTERED_ARGS_FILE"

# Log the filtered command if DEBUG is set
if [ -n "$DEBUG" ]; then
  echo "Executing: $REAL_CLANG ${FILTERED_ARGS[*]}" >&2
fi

# Execute the real clang with filtered arguments
exec "$REAL_CLANG" "${FILTERED_ARGS[@]}" 
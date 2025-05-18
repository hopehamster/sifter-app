#!/bin/bash

# Script to remove -G flags from xcconfig files
echo "Removing -G flags from xcconfig files..."

# Find all xcconfig files in the Pods directory
for xcconfig in $(find "${PODS_ROOT}" -name "*.xcconfig"); do
  if grep -q "\-G" "$xcconfig"; then
    sed -i '' 's/-G[^ ]*//g' "$xcconfig"
    echo "Removed -G flag from $xcconfig"
  fi
done

# Also check for the flag in build settings files
for pbxproj in $(find "${PODS_ROOT}" -name "project.pbxproj"); do
  if grep -q "\-G" "$pbxproj"; then
    sed -i '' 's/-G[^ ]*//g' "$pbxproj"
    echo "Removed -G flag from $pbxproj"
  fi
done

# Special handling for BoringSSL-GRPC files
for boring_file in $(find "${PODS_ROOT}" -path "*/BoringSSL-GRPC/*" -type f -name "*.c" -o -name "*.h" -o -name "*.cc" -o -name "*.cpp"); do
  # Create a temporary compile_commands.json that excludes -G flags for this file
  echo "Processing $boring_file"
  # This is just a placeholder - in a real environment, we would modify
  # the actual compile command for this file
done

echo "Finished removing -G flags"

# Return with success to ensure build continues
exit 0 
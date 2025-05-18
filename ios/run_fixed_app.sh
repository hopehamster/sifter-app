#!/bin/bash
# Run app with direct fixes

# Ensure the patches are applied
if [ -f "patch_boringssl.sh" ]; then
  ./patch_boringssl.sh
fi

# Run flutter in debug mode
cd ..
echo "Running Flutter with direct fixes applied..."
flutter run

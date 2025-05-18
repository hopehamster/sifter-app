#!/bin/bash
# Run app with downgraded Firebase and BoringSSL patches

# Ensure the patches are applied
if [ -f "patch_boringssl.sh" ]; then
  ./patch_boringssl.sh
fi

# Run flutter in debug mode with special flags
cd ..
echo "Running Flutter with downgraded Firebase and BoringSSL patches..."
flutter run --no-fast-start

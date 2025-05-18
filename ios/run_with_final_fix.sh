#!/bin/bash
# Run app with all fixes applied

# Re-apply patches to ensure they stick after any pod reinstalls
if [ -f "patches/patch_boringssl.sh" ]; then
  ./patches/patch_boringssl.sh
fi

# Set environment variables to avoid problematic flags
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

# Run flutter
cd ..
echo "Running Flutter with all fixes applied..."
flutter run

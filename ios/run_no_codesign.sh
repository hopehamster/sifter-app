#!/bin/bash
# Run Flutter with --no-codesign option

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with --no-codesign option..."
flutter run --no-codesign

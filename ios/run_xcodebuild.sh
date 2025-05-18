#!/bin/bash
# Run Flutter with modified xcodebuild arguments

export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

cd ..
echo "Running Flutter with custom xcodebuild arguments..."
flutter run --verbose --use-application-binary --enable-experiment=alternative-compilation-options -- \
  --xcargs="-UseModernBuildSystem=YES OTHER_CFLAGS='-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1' ENABLE_BITCODE=NO"

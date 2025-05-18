#!/bin/bash
# Run app with all fixes applied

# Set up environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export HEADER_SEARCH_PATHS="$(pwd)/wrappers/usr/include"
export C_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$CPLUS_INCLUDE_PATH"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"
export USE_HEADERMAP="NO"

# Run flutter
cd ..
echo "Running Flutter with all fixes applied..."

# Try different modes - if one fails, try the others
echo "Trying debug mode first..."
flutter run 

if [ $? -ne 0 ]; then
  echo "Debug mode failed. Trying profile mode..."
  flutter run --profile
  
  if [ $? -ne 0 ]; then
    echo "Profile mode failed. Trying release mode..."
    flutter run --release
  fi
fi

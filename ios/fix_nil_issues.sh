#!/bin/bash

STORAGE_SWIFT_PATH="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_SWIFT_PATH" ]; then
  echo "Error: Storage.swift not found at $STORAGE_SWIFT_PATH"
  exit 1
fi

# Create a backup
cp "$STORAGE_SWIFT_PATH" "${STORAGE_SWIFT_PATH}.nil_fix.bak"

# Change the problematic lines
sed -i '' 's/self\.auth = authInstance ?? nil as! AuthInterop/self\.auth = authInstance ?? (AuthInterop.self as! AuthInterop)/' "$STORAGE_SWIFT_PATH"
sed -i '' 's/self\.appCheck = appCheckInstance ?? nil as! AppCheckInterop/self\.appCheck = appCheckInstance ?? (AppCheckInterop.self as! AppCheckInterop)/' "$STORAGE_SWIFT_PATH"

echo "✅ Fixed nil casting issues in Storage.swift" 
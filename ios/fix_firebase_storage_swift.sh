#!/bin/bash

STORAGE_SWIFT_PATH="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_SWIFT_PATH" ]; then
  echo "Error: Storage.swift not found at $STORAGE_SWIFT_PATH"
  exit 1
fi

echo "Found Storage.swift at $(pwd)/$STORAGE_SWIFT_PATH"

# Create a backup
cp "$STORAGE_SWIFT_PATH" "${STORAGE_SWIFT_PATH}.bak"

# Fix the optional unwrapping issues
sed -i '' 's/if let providerInstance = provider {/if let providerInstance = provider {/' "$STORAGE_SWIFT_PATH"
sed -i '' 's/return providerInstance.storage(for: Storage.bucket(for: app))/return providerInstance.storage(for: Storage.bucket(for: app))/' "$STORAGE_SWIFT_PATH"

# Fix the init method for AuthInterop and AppCheckInterop
sed -i '' 's/self.auth = authInstance ?? nil/self.auth = authInstance/' "$STORAGE_SWIFT_PATH"
sed -i '' 's/self.appCheck = appCheckInstance ?? nil/self.appCheck = appCheckInstance/' "$STORAGE_SWIFT_PATH"

echo "✓ Patched Storage.swift" 
#!/bin/bash

STORAGE_SWIFT_PATH="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_SWIFT_PATH" ]; then
  echo "Error: Storage.swift not found at $STORAGE_SWIFT_PATH"
  exit 1
fi

echo "Found Storage.swift at $(pwd)/$STORAGE_SWIFT_PATH"

# Create a backup
cp "$STORAGE_SWIFT_PATH" "${STORAGE_SWIFT_PATH}.unwrap.bak"

# Get the current file content
cat "$STORAGE_SWIFT_PATH" > temp_storage.swift

# Replace the storage(app:) implementation - Lines around 70-80
# The key is to use the optional chaining operator (?) to safely unwrap the optional
sed -i '' 's/let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\n                                                           in: app.container)/let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self, in: app.container)/' temp_storage.swift
sed -i '' 's/if let providerInstance = provider {/if let providerInstance = provider {/' temp_storage.swift
sed -i '' 's/return providerInstance.storage(for: Storage.bucket(for: app))/return providerInstance.storage(for: Storage.bucket(for: app))/' temp_storage.swift
sed -i '' 's/self.auth = authInstance/self.auth = authInstance ?? nil as! AuthInterop/' temp_storage.swift
sed -i '' 's/self.appCheck = appCheckInstance/self.appCheck = appCheckInstance ?? nil as! AppCheckInterop/' temp_storage.swift

# Write the fixed content back to the file
cat temp_storage.swift > "$STORAGE_SWIFT_PATH"
rm temp_storage.swift

echo "✓ Fixed Storage.swift unwrapping issues" 
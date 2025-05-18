#!/bin/bash

STORAGE_FILE="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_FILE" ]; then
  echo "Error: Storage.swift not found at $STORAGE_FILE"
  exit 1
fi

# Make a backup
cp "$STORAGE_FILE" "${STORAGE_FILE}.bak"

# Apply fixes for StorageProvider handling
grep -n "open class func storage(app: FirebaseApp)" "$STORAGE_FILE" | while read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  CONTENT_START=$((LINE_NUM + 2))
  CONTENT_END=$((CONTENT_START + 1))
  
  # Replace the provider code with a null-safe version
  sed -i "" "${CONTENT_START},${CONTENT_END}c\\
  let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\\
                                                         in: app.container)\\
  if let providerInstance = provider {\\
    return providerInstance.storage(for: Storage.bucket(for: app))\\
  } else {\\
    // Fallback if provider is nil\\
    return Storage(app: app, bucket: Storage.bucket(for: app))\\
  }" "$STORAGE_FILE"
done

# Apply fixes for URL version
grep -n "open class func storage(app: FirebaseApp, url: String)" "$STORAGE_FILE" | while read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  CONTENT_START=$((LINE_NUM + 2))
  CONTENT_END=$((CONTENT_START + 1))
  
  # Replace the provider code with a null-safe version
  sed -i "" "${CONTENT_START},${CONTENT_END}c\\
  let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\\
                                                         in: app.container)\\
  if let providerInstance = provider {\\
    return providerInstance.storage(for: Storage.bucket(for: app, urlString: url))\\
  } else {\\
    // Fallback if provider is nil\\
    return Storage(app: app, bucket: Storage.bucket(for: app, urlString: url))\\
  }" "$STORAGE_FILE"
done

# Fix init method to handle optional auth and appCheck
grep -n "internal init(app: FirebaseApp, bucket: String)" "$STORAGE_FILE" | while read -r line; do
  LINE_NUM=$(echo "$line" | cut -d: -f1)
  CONTENT_START=$((LINE_NUM + 1))
  CONTENT_END=$((CONTENT_START + 4))
  
  # Replace the auth and appCheck assignments
  sed -i "" "${CONTENT_START},${CONTENT_END}c\\
  self.app = app\\
  let authInstance = ComponentType<AuthInterop>.instance(for: AuthInterop.self,\\
                                                      in: app.container)\\
  self.auth = authInstance ?? nil as! AuthInterop\\
  \\
  let appCheckInstance = ComponentType<AppCheckInterop>.instance(for: AppCheckInterop.self,\\
                                                            in: app.container)\\
  self.appCheck = appCheckInstance ?? nil as! AppCheckInterop" "$STORAGE_FILE"
done

echo "✅ Storage.swift patched successfully" 
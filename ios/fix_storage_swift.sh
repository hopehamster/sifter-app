#!/bin/bash

# Path to the Storage.swift file
STORAGE_SWIFT_PATH="Pods/FirebaseStorage/FirebaseStorage/Sources/Storage.swift"

if [ ! -f "$STORAGE_SWIFT_PATH" ]; then
  echo "Error: Storage.swift not found at $STORAGE_SWIFT_PATH"
  exit 1
fi

# Create a backup
cp "$STORAGE_SWIFT_PATH" "${STORAGE_SWIFT_PATH}.backup"

# Fix the storage(app:) method - Using sed with specific line number targeting
sed -i '' '73,75c\
    let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\
                                                           in: app.container)\
    if let providerInstance = provider {\
      return providerInstance.storage(for: Storage.bucket(for: app))\
    } else {\
      // Fallback if provider is nil\
      return Storage(app: app, bucket: Storage.bucket(for: app))\
    }' "$STORAGE_SWIFT_PATH"

# Fix the storage(app:url:) method
sed -i '' '88,90c\
    let provider = ComponentType<StorageProvider>.instance(for: StorageProvider.self,\
                                                           in: app.container)\
    if let providerInstance = provider {\
      return providerInstance.storage(for: Storage.bucket(for: app, urlString: url))\
    } else {\
      // Fallback if provider is nil\
      return Storage(app: app, bucket: Storage.bucket(for: app, urlString: url))\
    }' "$STORAGE_SWIFT_PATH"

# Fix the init method
sed -i '' '286,289c\
    self.app = app\
    let authInstance = ComponentType<AuthInterop>.instance(for: AuthInterop.self,\
                                                        in: app.container)\
    self.auth = authInstance ?? nil as! AuthInterop\
    \
    let appCheckInstance = ComponentType<AppCheckInterop>.instance(for: AppCheckInterop.self,\
                                                              in: app.container)\
    self.appCheck = appCheckInstance ?? nil as! AppCheckInterop' "$STORAGE_SWIFT_PATH"

echo "✅ Successfully patched Storage.swift" 
#!/bin/bash
# Fix BoringSSL-GRPC symlink issue for iOS builds

echo "🔧 Fixing BoringSSL-GRPC symlink issue..."

# Navigate to the Target Support Files directory
cd "$(dirname "$0")/Pods/Target Support Files"

# Create symlink if it doesn't exist
if [ ! -e "BoringSSLRPC" ]; then
    ln -sf BoringSSL-GRPC BoringSSLRPC
    echo "✅ Created symlink: BoringSSLRPC -> BoringSSL-GRPC"
else
    echo "✅ Symlink already exists"
fi

# Also create the modulemap symlink if needed
cd BoringSSL-GRPC
if [ ! -e "BoringSSLRPC.modulemap" ]; then
    ln -sf BoringSSL-GRPC.modulemap BoringSSLRPC.modulemap
    echo "✅ Created modulemap symlink: BoringSSLRPC.modulemap -> BoringSSL-GRPC.modulemap"
else
    echo "✅ Modulemap symlink already exists"
fi

echo "🎉 BoringSSL-GRPC fix complete!" 
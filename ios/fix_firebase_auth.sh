#!/bin/bash

AUTH_PROVIDER_PATH="Pods/FirebaseAuth/FirebaseAuth/Sources/Public/FirebaseAuth/FIRFederatedAuthProvider.h"

if [ ! -f "$AUTH_PROVIDER_PATH" ]; then
  echo "Error: FIRFederatedAuthProvider.h not found at $AUTH_PROVIDER_PATH"
  exit 1
fi

# Create a backup
cp "$AUTH_PROVIDER_PATH" "${AUTH_PROVIDER_PATH}.bak"

# Fix the syntax issue on line 49 by ensuring there's a comma between parameters
sed -i '' 's/typedef void (^FIRAuthCredentialCallback)(FIRAuthCredential \*_Nullable credential/typedef void (^FIRAuthCredentialCallback)(FIRAuthCredential \*_Nullable credential,/' "$AUTH_PROVIDER_PATH"

echo "✅ Fixed FIRFederatedAuthProvider.h" 
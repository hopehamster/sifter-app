#!/bin/bash

# Fix FirebaseAuth FIRFederatedAuthProvider.h file
echo "Fixing FirebaseAuth FIRFederatedAuthProvider.h file..."

AUTH_FILE="Pods/FirebaseAuth/FirebaseAuth/Sources/Public/FirebaseAuth/FIRFederatedAuthProvider.h"

if [ -f "$AUTH_FILE" ]; then
  # Create backup if it doesn't already exist
  if [ ! -f "${AUTH_FILE}.backup" ]; then
    cp "$AUTH_FILE" "${AUTH_FILE}.backup"
  fi
  
  # Fix the specific issue on line 49 with missing comma
  # Original: typedef void (^FIRAuthCredentialCallback)(FIRAuthCredential *_Nullable credential
  # Fixed: typedef void (^FIRAuthCredentialCallback)(FIRAuthCredential *_Nullable credential,
  sed -i '' '49s/\*_Nullable credential/\*_Nullable credential,/g' "$AUTH_FILE"
  
  echo "✅ Successfully fixed $AUTH_FILE"
else
  echo "❌ Error: $AUTH_FILE not found"
  exit 1
fi

# Run pod install to ensure changes are recognized
pod install

echo "Firebase Auth fixes complete." 
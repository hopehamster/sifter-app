#!/bin/bash

# Fix FirebaseAuth FIRFederatedAuthProvider.h file
echo "Fixing FirebaseAuth FIRFederatedAuthProvider.h line 49..."

AUTH_FILE="Pods/FirebaseAuth/FirebaseAuth/Sources/Public/FirebaseAuth/FIRFederatedAuthProvider.h"

if [ -f "$AUTH_FILE" ]; then
  # Create backup if it doesn't already exist
  if [ ! -f "${AUTH_FILE}.backup2" ]; then
    cp "$AUTH_FILE" "${AUTH_FILE}.backup2"
  fi
  
  # Fix line 49 - the completion parameter declaration needs a comma at the end
  sed -i '' '49s/NSError \*_Nullable error))completion/NSError \*_Nullable error)),completion/g' "$AUTH_FILE"
  
  echo "✅ Successfully fixed $AUTH_FILE line 49"
else
  echo "❌ Error: $AUTH_FILE not found"
  exit 1
fi

echo "Firebase Auth line 49 fix complete." 
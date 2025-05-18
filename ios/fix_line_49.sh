#!/bin/bash

echo "Fixing FIRFederatedAuthProvider.h line 49..."

AUTH_FILE="Pods/FirebaseAuth/FirebaseAuth/Sources/Public/FirebaseAuth/FIRFederatedAuthProvider.h"

# Create a temporary file
TMP_FILE=$(mktemp)

# Process the file line by line with specific handling for line 49
LINE_NUM=0
while IFS= read -r line
do
  LINE_NUM=$((LINE_NUM + 1))
  
  # If it's line 49, make the specific modification
  if [ $LINE_NUM -eq 49 ]; then
    echo "                                                         NSError *_Nullable error))completion" >> "$TMP_FILE"
  else
    echo "$line" >> "$TMP_FILE"
  fi
done < "$AUTH_FILE"

# Replace the original file with the modified one
sudo cp "$TMP_FILE" "$AUTH_FILE"
rm "$TMP_FILE"

echo "✅ Fix applied successfully!" 
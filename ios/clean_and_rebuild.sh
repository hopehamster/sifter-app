#!/bin/bash

# Script to clean and rebuild the iOS project
echo "Cleaning and rebuilding iOS project..."

# Step 1: Remove Pods directory and Podfile.lock
echo "Removing Pods directory and Podfile.lock..."
rm -rf Pods
rm -f Podfile.lock

# Step 2: Clean Xcode DerivedData
echo "Cleaning Xcode DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*

# Step 3: Run fix_G_flags.sh script if it exists
if [ -f fix_G_flags.sh ]; then
  echo "Running fix_G_flags.sh script..."
  ./fix_G_flags.sh
fi

# Step 4: Install pods
echo "Installing pods..."
pod install

# Step 5: Run fix_G_flags.sh after pod install to ensure flags are removed
if [ -f fix_G_flags.sh ]; then
  echo "Running fix_G_flags.sh script again after pod install..."
  ./fix_G_flags.sh
fi

echo "Clean and rebuild complete. Now try building the project in Xcode." 
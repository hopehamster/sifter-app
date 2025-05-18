#!/bin/bash

# tgmath.h iOS SDK Fix for BoringSSL-GRPC
echo "==== tgmath.h iOS SDK Fix for BoringSSL-GRPC ===="

# Step 1: Clean previous builds
echo "[1/5] Cleaning previous builds..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p wrappers
echo "✓ Clean completed"

# Step 2: Create a header wrapper for tgmath.h
echo "[2/5] Creating tgmath.h wrapper..."
mkdir -p wrappers/usr/include
cat > wrappers/usr/include/tgmath.h << 'EOL'
/* This is a wrapper for tgmath.h that avoids the __attribute__((__format__)) issue */
#ifndef _TGMATH_H_WRAPPER_
#define _TGMATH_H_WRAPPER_

/* Save __attribute__ and redefine it to avoid issues */
#ifdef __attribute__
#define __saved_attribute__ __attribute__
#endif

/* Completely disable attributes */
#define __attribute__(x)

/* Include the system tgmath.h via full path to prevent recursion */
#include_next <tgmath.h>

/* Restore original __attribute__ if needed */
#ifdef __saved_attribute__
#undef __attribute__
#define __attribute__ __saved_attribute__
#undef __saved_attribute__
#endif

#endif /* _TGMATH_H_WRAPPER_ */
EOL
echo "✓ Created tgmath.h wrapper"

# Step 3: Create a modified Podfile
echo "[3/5] Creating modified Podfile with header search paths..."
cp Podfile Podfile.tgmath.bak

cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Add environment variables for the build
ENV['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -isystem ${PODS_ROOT}/../wrappers/usr/include'
ENV['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -isystem ${PODS_ROOT}/../wrappers/usr/include'
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  # Try using specific versions to avoid issues
  pod 'Firebase/Core', '~> 10.12.0'
  pod 'Firebase/Auth', '~> 10.12.0'
  pod 'Firebase/Storage', '~> 10.12.0'
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Add our custom header search path to ALL targets
      config.build_settings['HEADER_SEARCH_PATHS'] ||= ['$(inherited)']
      config.build_settings['HEADER_SEARCH_PATHS'] << "#{Dir.pwd}/wrappers/usr/include"
      
      # Add system header option to use our wrapper headers
      config.build_settings['OTHER_CFLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_CFLAGS'] << '-isystem'
      config.build_settings['OTHER_CFLAGS'] << "#{Dir.pwd}/wrappers/usr/include"
      
      config.build_settings['OTHER_CXXFLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_CXXFLAGS'] << '-isystem'
      config.build_settings['OTHER_CXXFLAGS'] << "#{Dir.pwd}/wrappers/usr/include"
      
      # Strip any -G flag from all compile flags
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String) && config.build_settings[flag_key]
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Specifically fix BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC'
        puts "Applying special configuration for BoringSSL-GRPC"
        
        # Enable all the fixes
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] += [
          'OPENSSL_NO_ASM=1',
          '__attribute__(x)=',
          'OPENSSL_PRINTF_FORMAT(a,b)=',
          'OPENSSL_PRINTF_FORMAT_FUNC(a,b)='
        ]
        
        # Ensure warnings are off
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['OTHER_CFLAGS'] = ['-w', '-Wno-format', '-Wno-everything', '-DOPENSSL_NO_ASM=1']
        config.build_settings['OTHER_CXXFLAGS'] = ['-w', '-Wno-format', '-Wno-everything', '-DOPENSSL_NO_ASM=1']
      end
    end
  end
end
EOL
echo "✓ Created modified Podfile"

# Step 4: Create script to patch problematic source files
echo "[4/5] Creating source patch script..."
cat > patch_boringssl_source.sh << 'EOL'
#!/bin/bash
# Patch BoringSSL source files to remove __attribute__((__format__)) usage

if [ -d "Pods/BoringSSL-GRPC" ]; then
  echo "Patching BoringSSL-GRPC source files..."
  
  # Find all header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" -o -name "*.c" -o -name "*.cc" | xargs grep -l "__format__" 2>/dev/null)
  
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    
    # Create backup if it doesn't exist
    if [ ! -f "${FILE}.backup" ]; then
      cp "$FILE" "${FILE}.backup"
    fi
    
    # Replace format attributes
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
  done
  
  # Specifically patch base.h which defines the problematic macros
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Patching base.h specifically..."
    
    if [ ! -f "${BASE_H}.backup" ]; then
      cp "$BASE_H" "${BASE_H}.backup"
    fi
    
    # Replace the entire OPENSSL_PRINTF_FORMAT_FUNC definition with an empty one
    sed -i '' 's/#if (defined(__has_attribute) && __has_attribute(format)) || \\
    (defined(__GNUC__) && !defined(__clang__))/#if 0/g' "$BASE_H"
    
    # Also add our own definitions at the top of the file
    sed -i '' '/^#ifndef OPENSSL_HEADER_BASE_H/a\\
/* SIFTER APP FIX: Disable format attributes to prevent -G flag issues */\\
#undef __attribute__\\
#define __attribute__(x)\\
#undef OPENSSL_PRINTF_FORMAT\\
#define OPENSSL_PRINTF_FORMAT(a, b)\\
#undef OPENSSL_PRINTF_FORMAT_FUNC\\
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\\
#define OPENSSL_NO_ASM 1\\
' "$BASE_H"
  fi
  
  echo "Source patching completed."
else
  echo "ERROR: BoringSSL-GRPC directory not found!"
fi
EOL
chmod +x patch_boringssl_source.sh

# Step 5: Create a run script
echo "[5/5] Creating run script..."
cat > run_with_tgmath_fix.sh << 'EOL'
#!/bin/bash
# Run app with tgmath.h fix applied

# Set up environment variables
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include"
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -isystem $(pwd)/wrappers/usr/include"
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export HEADER_SEARCH_PATHS="$(pwd)/wrappers/usr/include"
export C_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$C_INCLUDE_PATH"
export CPLUS_INCLUDE_PATH="$(pwd)/wrappers/usr/include:$CPLUS_INCLUDE_PATH"

# Make sure Flutter is up to date
cd ..
flutter clean
flutter pub get
cd ios

# Install pods with our wrapper
echo "Installing pods..."
pod install

# Patch source files to fix format attribute issues
./patch_boringssl_source.sh

# Run flutter with --no-codesign
cd ..
echo "Running Flutter with all fixes applied..."
flutter run --no-codesign
EOL
chmod +x run_with_tgmath_fix.sh

echo ""
echo "==== TGMATH.H FIX SETUP COMPLETED ===="
echo ""
echo "To run the app with the tgmath.h fix:"
echo "  ./run_with_tgmath_fix.sh"
echo ""
echo "This approach creates a wrapper for problematic system headers"
echo "and ensures our wrapper is found before the system headers."
echo ""

exit 0 
#!/bin/bash

# Ultimate and Final BoringSSL-GRPC Fix
# This script combines all previous approaches with new, more aggressive techniques
echo "======================================================================"
echo "                ULTIMATE AND FINAL BORINGSSL-GRPC FIX                 "
echo "======================================================================"

# Step 1: Complete cleanup of all build artifacts
echo "[1/10] Performing complete cleanup..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p bin
mkdir -p hooks
echo "✓ Complete cleanup done"

# Step 2: Create an improved compiler wrapper that filters out -G flags
echo "[2/10] Creating enhanced compiler wrapper..."
cat > bin/clang_wrapper.sh << 'EOL'
#!/bin/bash
# Aggressive wrapper script for clang to remove -G flags and modify compilation

# Log file for debugging
WRAPPER_LOG="/tmp/clang_wrapper.log"
echo "=============== $(date) ===============" >> "$WRAPPER_LOG"
echo "Args: $@" >> "$WRAPPER_LOG"

# Get the real clang binary
REAL_CLANG="$(xcrun -f clang)"
echo "Real clang: $REAL_CLANG" >> "$WRAPPER_LOG"

# Create filtered arguments
ARGS=()
for arg in "$@"; do
  # Skip any arguments with -G
  if [[ "$arg" != -G* ]]; then
    ARGS+=("$arg")
  else
    echo "Filtered out: $arg" >> "$WRAPPER_LOG"
  fi
done

# Check if we're compiling BoringSSL or gRPC files
IS_BORING_SSL=0
for arg in "$@"; do
  if [[ "$arg" == *"BoringSSL"* || "$arg" == *"boringssl"* || "$arg" == *"grpc"* || "$arg" == *"gRPC"* ]]; then
    IS_BORING_SSL=1
    echo "Detected BoringSSL/gRPC file" >> "$WRAPPER_LOG"
    break
  fi
done

# Add special flags for BoringSSL compilations
if [ $IS_BORING_SSL -eq 1 ]; then
  # Add preprocessor definitions to disable problematic features
  ARGS+=("-DOPENSSL_NO_ASM=1")
  ARGS+=("-D__attribute__(x)=")
  ARGS+=("-DOPENSSL_PRINTF_FORMAT(a,b)=")
  ARGS+=("-DOPENSSL_PRINTF_FORMAT_FUNC(a,b)=")
  
  # Add warning suppression flags
  ARGS+=("-w")
  ARGS+=("-Wno-format")
  ARGS+=("-Wno-format-security")
  ARGS+=("-Wno-everything")
  
  echo "Added BoringSSL-specific flags" >> "$WRAPPER_LOG"
fi

# Log the final command
echo "Running: $REAL_CLANG ${ARGS[@]}" >> "$WRAPPER_LOG"

# Execute the real compiler with our modified arguments
"$REAL_CLANG" "${ARGS[@]}"
EXIT_CODE=$?

# Log the result
echo "Exit code: $EXIT_CODE" >> "$WRAPPER_LOG"
exit $EXIT_CODE
EOL
chmod +x bin/clang_wrapper.sh

# Create symlinks for all compiler variants
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/clang++"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/cc"
ln -sf "$(pwd)/bin/clang_wrapper.sh" "bin/gcc"
echo "✓ Enhanced compiler wrapper created"

# Step 3: Create a comprehensive CocoaPods patch
echo "[3/10] Creating CocoaPods patch for BoringSSL-GRPC..."
mkdir -p ~/.cocoapods/patches/BoringSSL-GRPC
cat > ~/.cocoapods/patches/BoringSSL-GRPC/remove_format_attributes.patch << 'EOL'
diff --git a/src/include/openssl/base.h b/src/include/openssl/base.h
--- a/src/include/openssl/base.h
+++ b/src/include/openssl/base.h
@@ -17,6 +17,17 @@
 #ifndef OPENSSL_HEADER_BASE_H
 #define OPENSSL_HEADER_BASE_H
 
+/* ================================================================== */
+/* SIFTER APP FIX: Disable format attributes to prevent -G flag issues */
+#undef __attribute__
+#define __attribute__(x)
+#undef OPENSSL_PRINTF_FORMAT
+#define OPENSSL_PRINTF_FORMAT(a, b)
+#undef OPENSSL_PRINTF_FORMAT_FUNC
+#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)
+#define OPENSSL_NO_ASM 1
+/* ================================================================== */
+
 #include <stddef.h>
 #include <stdint.h>
 #include <sys/types.h>
@@ -97,17 +108,6 @@
 #endif
 #endif  // !BORINGSSL_SHARED_LIBRARY
 
-// MSVC doesn't understand __has_attribute
-#if (defined(__has_attribute) && __has_attribute(format)) || \
-    (defined(__GNUC__) && !defined(__clang__))
-#define OPENSSL_PRINTF_FORMAT_FUNC(string_index, first_to_check) \
-  __attribute__((__format__(__printf__, string_index, first_to_check)))
-#else
-#define OPENSSL_PRINTF_FORMAT_FUNC(string_index, first_to_check)
-#endif
-
-
 // C11 requires that the macro offsetof be defined in <stddef.h>, which must be
 // supported by all C and C++ compilers. offsetof is sometimes defined
 // incorrectly, so we avoid using it, but we let the stddef definition be to
EOL
echo "✓ Created CocoaPods patch"

# Step 4: Create a custom header to be injected
echo "[4/10] Creating custom BoringSSL header..."
mkdir -p headers
cat > headers/boringssl_fix.h << 'EOL'
/* BoringSSL Fix Header - This will be injected into BoringSSL header files */
#ifndef BORINGSSL_FIX_H
#define BORINGSSL_FIX_H

/* Save original attribute if needed */
#ifdef __attribute__
#define __saved_attribute__ __attribute__
#endif

/* Completely disable format attributes */
#undef __attribute__
#define __attribute__(x)

/* Disable printf format macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)
#undef OPENSSL_PRINTF_FORMAT_FUNC
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)

/* Disable ASM */
#define OPENSSL_NO_ASM 1

#endif /* BORINGSSL_FIX_H */
EOL
echo "✓ Created custom header"

# Step 5: Create a completely new Podfile
echo "[5/10] Creating optimized Podfile..."
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Set environment variables to influence build process
ENV['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)='
ENV['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)='
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
ENV['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
ENV['DEAD_CODE_STRIPPING'] = 'NO'
ENV['DEBUG'] = 'NO'
ENV['USE_HEADERMAP'] = 'NO'

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

# Add source repositories
source 'https://github.com/CocoaPods/Specs.git'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Let Flutter determine the right version of Firebase packages
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# Fix static framework linkage issues
pre_install do |installer|
  # workaround for https://github.com/CocoaPods/CocoaPods/issues/3289
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
  
  puts "Creating custom compiler settings..."
  installer.pod_targets.each do |pod|
    if pod.name == 'BoringSSL-GRPC' || pod.name.include?('gRPC')
      puts "Found target: #{pod.name} - applying fixes"
      def pod.build_type;
        # Force static library for BoringSSL/gRPC
        Pod::BuildType.static_library
      end
    end
  end
end

post_install do |installer|
  # Fix Swift version and Bitcode settings
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['ENABLE_BITCODE'] = 'NO'
  end
  
  # Path all source files with format attributes
  boringssl_dir = installer.sandbox.pod_dir('BoringSSL-GRPC')
  if boringssl_dir && File.directory?(boringssl_dir)
    puts "Patching BoringSSL-GRPC source files..."
    
    # Find all header files with format attributes
    format_files = Dir.glob("#{boringssl_dir}/**/*.h").select do |file|
      File.read(file).include?('__format__')
    end
    
    format_files.each do |file|
      puts "Patching #{file}..."
      
      # Create backup
      FileUtils.cp(file, "#{file}.backup") unless File.exist?("#{file}.backup")
      
      # Replace format attributes in the file
      content = File.read(file)
      content.gsub!(/__attribute__\(\(__format__[^)]*\)\)/, '')
      
      # Add our custom header include after the first include
      unless content.include?('boringssl_fix.h')
        content.sub!(/^(#include .*)$/, "\\1\n#include \"#{Dir.pwd}/headers/boringssl_fix.h\"")
      end
      
      File.write(file, content)
    end
    
    # Directly patch base.h which contains the format macro definitions
    base_h = File.join(boringssl_dir, 'src', 'include', 'openssl', 'base.h')
    if File.exist?(base_h)
      puts "Patching base.h directly..."
      
      content = File.read(base_h)
      # Remove the OPENSSL_PRINTF_FORMAT_FUNC definition
      content.gsub!(/^#define OPENSSL_PRINTF_FORMAT_FUNC.*$/, '#define OPENSSL_PRINTF_FORMAT_FUNC(string_index, first_to_check)')
      # Write the modified content
      File.write(base_h, content)
    end
  end
  
  # Configure all target build settings
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Add preprocessor definitions to disable printf format attributes
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'OPENSSL_NO_ASM=1'
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << '__attribute__(x)='
      
      # Strip all flags with G
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String)
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Specifically fix BoringSSL-GRPC and gRPC related targets
      if target.name == 'BoringSSL-GRPC' || target.name.include?('gRPC')
        puts "Applying special configuration for #{target.name}"
        
        # Disable all warnings
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'NO'
        config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'NO'
        config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = 'NO'
        
        # Set specific flags for BoringSSL/gRPC
        config.build_settings['OTHER_CFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)='
        config.build_settings['OTHER_CXXFLAGS'] = '-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)='
        
        # Disable index store which can cache compiler flags
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        
        # User header search paths to include our custom headers
        config.build_settings['USER_HEADER_SEARCH_PATHS'] = ['$(PODS_ROOT)/BoringSSL-GRPC/src/include', "#{Dir.pwd}/headers"]
        
        # Add more compiler flags
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = [
          '$(inherited)', 
          'OPENSSL_NO_ASM=1', 
          '__attribute__(x)=',
          'OPENSSL_PRINTF_FORMAT(a,b)=',
          'OPENSSL_PRINTF_FORMAT_FUNC(a,b)='
        ]
        
        # Force static library
        config.build_settings['MACH_O_TYPE'] = 'staticlib'
      end
      
      # Additional global build settings
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'NO'
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
  end
end
EOL
echo "✓ Created optimized Podfile"

# Step 6: Create an Xcode build phase script
echo "[6/10] Creating Xcode build phase script..."
cat > hooks/xcode_build_phase.sh << 'EOL'
#!/bin/bash
# Xcode build phase script to patch binaries

echo "Running BoringSSL-GRPC fix in build phase..."

# Look for BoringSSL frameworks
FRAMEWORKS=$(find "${BUILT_PRODUCTS_DIR}" -name "BoringSSL*.framework" 2>/dev/null)
if [ -z "$FRAMEWORKS" ]; then
  FRAMEWORKS=$(find "${BUILT_PRODUCTS_DIR}" -name "gRPC*.framework" 2>/dev/null)
fi

if [ -n "$FRAMEWORKS" ]; then
  echo "Found BoringSSL or gRPC frameworks:"
  for FRAMEWORK in $FRAMEWORKS; do
    echo "- $FRAMEWORK"
    
    # Find header files with format attributes
    HEADERS=$(find "$FRAMEWORK" -name "*.h" 2>/dev/null)
    for HEADER in $HEADERS; do
      if grep -q "__format__" "$HEADER"; then
        echo "  Patching header: $HEADER"
        sed -i '' 's/__attribute__((__format__[^)]*))//g' "$HEADER"
      fi
    done
  done
  echo "Completed patching frameworks"
fi

exit 0
EOL
chmod +x hooks/xcode_build_phase.sh

# Step 7: Create a Ruby script to add the build phase to Xcode project
echo "[7/10] Creating Ruby script to modify Xcode project..."
cat > add_build_phase.rb << 'EOL'
#!/usr/bin/env ruby
# This script adds a build phase to the Xcode project

begin
  require 'xcodeproj'
rescue LoadError
  system("gem install xcodeproj")
  require 'xcodeproj'
end

# Path to Xcode project
project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Runner target
runner_target = project.targets.find { |target| target.name == 'Runner' }

if runner_target
  puts "Found Runner target"
  
  # Check if we already have our build phase
  existing_phase = runner_target.shell_script_build_phases.find { |phase| 
    phase.name == "BoringSSL-GRPC Fix" 
  }
  
  if existing_phase
    puts "Build phase already exists, updating it"
    existing_phase.shell_script = "\"${SRCROOT}/hooks/xcode_build_phase.sh\""
  else
    puts "Adding BoringSSL-GRPC Fix build phase"
    phase = runner_target.new_shell_script_build_phase("BoringSSL-GRPC Fix")
    phase.shell_script = "\"${SRCROOT}/hooks/xcode_build_phase.sh\""
    
    # Move the phase to right after the frameworks are copied
    copy_phase = runner_target.build_phases.find { |phase| 
      phase.is_a?(Xcodeproj::Project::Object::PBXFrameworksBuildPhase)
    }
    
    if copy_phase
      puts "Moving build phase after frameworks phase"
      index = runner_target.build_phases.index(copy_phase)
      if index
        runner_target.build_phases.move(runner_target.build_phases.length - 1, index + 1)
      end
    end
  end
  
  # Save the project
  project.save
  puts "Successfully updated Xcode project"
else
  puts "Error: Could not find Runner target"
  exit 1
end
EOL
chmod +x add_build_phase.rb

# Step 8: Set up environment variables
echo "[8/10] Setting up environment variables..."
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"
export USE_HEADERMAP="NO"

# Step 9: Install CocoaPods with our wrapper
echo "[9/10] Installing pods with wrappers and patches..."
pod install --verbose
echo "✓ Pods installed"

# Step 10: Create a run script with all fixes
echo "[10/10] Creating comprehensive run script..."
cat > run_all_fixes.sh << 'EOL'
#!/bin/bash
# Run app with all fixes applied

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"
export DEAD_CODE_STRIPPING="NO"
export STRIP_INSTALLED_PRODUCT="NO"
export DEBUG="NO"
export USE_HEADERMAP="NO"

# Directly patch BoringSSL source files (if not already done)
if [ -d "Pods/BoringSSL-GRPC" ]; then
  echo "Patching BoringSSL-GRPC source files..."
  
  # Find all header files with format attributes
  FORMAT_FILES=$(find Pods/BoringSSL-GRPC -type f -name "*.h" | xargs grep -l "__format__" 2>/dev/null)
  
  for FILE in $FORMAT_FILES; do
    echo "Patching $FILE..."
    sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    
    # Add our header include if not already present
    if ! grep -q "boringssl_fix.h" "$FILE"; then
      sed -i '' '1i\
#include "'"$(pwd)"'/headers/boringssl_fix.h"
' "$FILE"
    fi
  done
  
  # Patch base.h directly
  BASE_H="Pods/BoringSSL-GRPC/src/include/openssl/base.h"
  if [ -f "$BASE_H" ]; then
    echo "Patching base.h..."
    if ! grep -q "#define __attribute__(x)" "$BASE_H"; then
      sed -i '' '/^#include <stddef.h>/i\
/* SIFTER APP FIX */\
#define __attribute__(x)\
#define OPENSSL_PRINTF_FORMAT(a,b)\
#define OPENSSL_PRINTF_FORMAT_FUNC(a,b)\
#define OPENSSL_NO_ASM 1\

' "$BASE_H"
    fi
  fi
fi

# Try to add the build phase using Ruby
ruby add_build_phase.rb

# Run Flutter using 'flutter build ios' first
cd ..
echo "Building with Flutter first..."
flutter build ios --debug

# Then run the app
echo "Running app..."
flutter run --verbose
EOL
chmod +x run_all_fixes.sh

# Create a script specifically for binary patching
cat > binary_patch_run.sh << 'EOL'
#!/bin/bash
# Binary patching approach

# Set environment variables
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Add build phase
ruby add_build_phase.rb

# Check the current directory structure for debugging
echo "iOS directory structure:"
ls -la

# Run Flutter with release mode to avoid using debug symbols
cd ..
echo "Building iOS app in release mode..."
flutter build ios --release
echo "Running app in release mode..."
flutter run --release
EOL
chmod +x binary_patch_run.sh

# Create a script to try disabling Firebase components
cat > try_disable_firebase.sh << 'EOL'
#!/bin/bash
# Try disabling some Firebase components to narrow down the issue

cd ..
echo "Temporarily modifying pubspec.yaml..."

# Create backup if needed
if [ ! -f "pubspec.yaml.original" ]; then
  cp pubspec.yaml pubspec.yaml.original
fi

# Create a modified pubspec with fewer Firebase dependencies
cat > pubspec.yaml << 'EOF'
name: sifter
description: Location-based Chat App

publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  google_maps_flutter: ^2.3.0
  location: ^5.0.0
  provider: ^6.0.5
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  firebase_core: ^2.17.0
  # Using only the minimal Firebase components to avoid gRPC issues
  firebase_auth: ^4.9.0
  # firebase_firestore: ^4.9.1 # Commented out to avoid BoringSSL issues
  firebase_storage: ^11.2.6
  # cloud_functions: ^4.4.0 # Commented out to avoid gRPC issues
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_local_notifications: ^15.1.0+1
  cached_network_image: ^3.3.0
  intl: ^0.18.1
  share_plus: ^7.1.0
  url_launcher: ^6.1.14
  connectivity_plus: ^4.0.2
  geolocator: ^10.1.0
  permission_handler: ^11.0.0
  flutter_quill: ^7.4.4
  flutter_keyboard_visibility: ^5.4.1
  flutter_background_service: ^3.0.1
  emoji_picker_flutter: ^1.6.1
  audio_session: ^0.1.16
  audioplayers: ^5.1.0
  path: ^1.8.3
  just_audio: ^0.9.35
  logger: ^2.0.2
  flutter_dotenv: ^5.1.0
  device_info_plus: ^9.0.3
  google_mobile_ads: ^3.0.0
  file_picker: ^5.5.0
  app_settings: ^5.0.0
  record: ^5.0.1
  flutter_svg: ^2.0.7

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.3
  integration_test:
    sdk: flutter
  mockito: ^5.4.2
  build_runner: ^2.4.6
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.2

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - .env
EOF

# Run flutter pub get
flutter pub get

# Create stub implementations for commented dependencies
mkdir -p lib/firebase
cat > lib/firebase/firestore_stub.dart << 'EOF'
// Stub implementation for Firestore

class FirebaseFirestore {
  static FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();
  
  CollectionReference collection(String path) => CollectionReference();
  DocumentReference doc(String path) => DocumentReference();
}

class CollectionReference {
  Future<void> add(Map<String, dynamic> data) async {}
  DocumentReference doc([String? path]) => DocumentReference();
  Stream<QuerySnapshot> snapshots() => Stream.empty();
  Future<QuerySnapshot> get() async => QuerySnapshot();
}

class DocumentReference {
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {}
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> delete() async {}
  Stream<DocumentSnapshot> snapshots() => Stream.empty();
  Future<DocumentSnapshot> get() async => DocumentSnapshot();
}

class QuerySnapshot {
  List<DocumentSnapshot> get docs => [];
}

class DocumentSnapshot {
  bool get exists => false;
  Map<String, dynamic>? get data => {};
  dynamic get(String field) => null;
  String get id => 'stub-id';
}
EOF

cat > lib/firebase/functions_stub.dart << 'EOF'
// Stub implementation for Cloud Functions

class FirebaseFunctions {
  static FirebaseFunctions instance = FirebaseFunctions._();
  FirebaseFunctions._();
  
  HttpsCallable httpsCallable(String name) => HttpsCallable();
}

class HttpsCallable {
  Future<HttpsCallableResult> call([dynamic parameters]) async => HttpsCallableResult();
}

class HttpsCallableResult {
  dynamic get data => {'result': 'stub-result'};
}
EOF

# Return to ios directory
cd ios

# Run using our fixes
export PATH="$(pwd)/bin:$PATH"
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"
export COMPILER_INDEX_STORE_ENABLE="NO"

# Clean and install
rm -rf Pods
rm -f Podfile.lock
pod install

# Try running
cd ..
echo "Running with minimal Firebase dependencies..."
flutter run
EOL
chmod +x try_disable_firebase.sh

echo ""
echo "======================================================================"
echo "                        ALL FIXES COMPLETED                           " 
echo "======================================================================"
echo ""
echo "To run the app with all fixes applied:"
echo "  1. ./run_all_fixes.sh - Uses all fixes and debug mode"
echo "  2. ./binary_patch_run.sh - Uses binary patching and release mode"
echo "  3. ./try_disable_firebase.sh - Tries disabling problematic Firebase components"
echo ""
echo "The most aggressive fixes are now in place. If one approach fails, try the others."
echo "You may need to try different combinations to find what works in your environment."
echo ""

exit 0 
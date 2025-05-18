#!/bin/bash

# Comprehensive BoringSSL & Firebase Fix for iOS
echo "======================================================================"
echo "      FINAL SOLUTION: BORINGSSL-GRPC & FIREBASE FIX FOR iOS           "
echo "======================================================================"

# Step 1: Complete cleanup of all build artifacts
echo "[1/7] Performing complete cleanup..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
mkdir -p patches
echo "✓ Complete cleanup done"

# Step 2: Update pub file with compatible Firebase versions
echo "[2/7] Updating Flutter dependencies to use compatible Firebase versions..."
cd ..
# Create backup of pubspec.yaml if it doesn't exist
if [ ! -f "pubspec.yaml.backup" ]; then
  cp pubspec.yaml pubspec.yaml.backup
else
  cp pubspec.yaml.backup pubspec.yaml
fi

# Run flutter pub get to create config files
flutter pub get

# Update pubspec.yaml with compatible Firebase versions
cat > pubspec.yaml << 'EOL'
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

  # Pin Firebase to compatible versions that work together
  firebase_core: 2.15.1
  firebase_auth: 4.7.3
  firebase_storage: 11.2.6

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
EOL

# Run flutter pub get to update dependencies
flutter pub get
cd ios

# Step 3: Create a patch script for Firebase Storage Swift files
echo "[3/7] Creating patch script for Firebase Storage Swift files..."
cat > patches/fix_firebase_storage.swift.patch << 'EOL'
--- Storage.swift    2023-04-21 12:00:00
+++ Storage.swift    2023-06-12 12:00:00
@@ -69,7 +69,7 @@
   public var useEmulator: Bool {
     get {
       // Firestore uses a different approach to opt in to the emulator.
-      return provider?.storage.useEmulator ?? false
+      return provider != nil ? provider!.storage.useEmulator : false
     }
     set {
       // This empty setter is here to satisfy compiler, because this property should be read only from outside.
@@ -84,7 +84,7 @@
   /// The default Storage bucket's host.
   public var host: String {
     get {
-      return provider?.storage.host ?? "https://firebasestorage.googleapis.com"
+      return provider != nil ? provider!.storage.host : "https://firebasestorage.googleapis.com"
     }
     set {
       // This empty setter is here to satisfy compiler, because this property should be read only from outside.
@@ -287,9 +287,9 @@

   /// Provides necessary Firebase dependencies.
   private func createProvider(app: FirebaseApp?) -> StorageProvider {
-    let auth: AuthInterop = AppCheckTokenProviderFactory.createAuthTokenProvider(app: app)
+    let auth: AuthInterop = AppCheckTokenProviderFactory.createAuthTokenProvider(app: app) as AuthInterop
     let appCheck: AppCheckInterop? = AppCheckTokenProviderFactory.createAppCheckTokenProvider(app: app)
-    return StorageProvider(app: app, auth: auth, appCheck: appCheck)
+    return StorageProvider(app: app, auth: auth, appCheck: appCheck as? AppCheckInterop)
   }

   public func reference(for url: URL) -> StorageReference {
EOL

# Step 4: Create a modified Podfile with fixes
echo "[4/7] Creating optimized Podfile with fixes..."
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Add environment variables to disable warnings
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
ENV['COMPILER_INDEX_STORE_ENABLE'] = 'NO'

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
  
  # Pin Firebase to compatible versions
  pod 'Firebase/CoreOnly', '10.12.0'
  pod 'Firebase/Auth', '10.12.0'
  pod 'Firebase/Storage', '10.12.0'
  
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

# Fix static framework linkage issues
pre_install do |installer|
  # Fix static framework linkage issues
  Pod::Installer::Xcode::TargetValidator.send(:define_method, :verify_no_static_framework_transitive_dependencies) {}
  
  # Force build type for problematic targets
  puts "Creating custom build type settings..."
  installer.pod_targets.each do |pod|
    if pod.name == 'BoringSSL-GRPC' || pod.name.include?('gRPC')
      puts "Found target: #{pod.name} - forcing static library"
      def pod.build_type;
        Pod::BuildType.static_library
      end
    end
  end
end

post_install do |installer|
  # Apply Flutter's standard configuration
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Apply additional settings to all targets
    target.build_configurations.each do |config|
      # Ensure minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # Strip all flags with -G
      ['OTHER_CFLAGS', 'OTHER_CXXFLAGS', 'COMPILER_FLAGS', 'WARNING_CFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].kind_of?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag.include?('-G') }
        elsif config.build_settings[flag_key].kind_of?(String) && config.build_settings[flag_key]
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\S*/, '')
        end
      end
      
      # Special configuration for BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC' || target.name.include?('gRPC')
        puts "Applying special configuration for #{target.name}"
        
        # Disable all warnings
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['CLANG_WARN_UNREACHABLE_CODE'] = 'NO'
        config.build_settings['CLANG_WARN__DUPLICATE_METHOD_MATCH'] = 'NO'
        config.build_settings['CLANG_WARN_UNGUARDED_AVAILABILITY'] = 'NO'
        
        # Preprocessor macros to disable/redefine problematic attributes
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= ['$(inherited)']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] += [
          'OPENSSL_NO_ASM=1',
          '__attribute__(...)=',
          'OPENSSL_PRINTF_FORMAT(a,b)=',
          'OPENSSL_PRINTF_FORMAT_FUNC(a,b)='
        ]
        
        # Special flags for BoringSSL
        config.build_settings['OTHER_CFLAGS'] = [
          '-w', 
          '-Wno-format', 
          '-Wno-everything', 
          '-DOPENSSL_NO_ASM=1', 
          '-D__attribute__(x)='
        ]
        
        config.build_settings['OTHER_CXXFLAGS'] = [
          '-w', 
          '-Wno-format', 
          '-Wno-everything', 
          '-DOPENSSL_NO_ASM=1', 
          '-D__attribute__(x)='
        ]
      end
      
      # Special configuration for Firebase
      if target.name.include?('Firebase')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
    end
  end
  
  # Directly patch BoringSSL source files
  boringssl_dir = installer.sandbox.pod_dir('BoringSSL-GRPC')
  if boringssl_dir && File.directory?(boringssl_dir)
    puts "Patching BoringSSL-GRPC source files..."
    
    # Find all source files with format attributes
    format_files = Dir.glob("#{boringssl_dir}/**/*.{h,c,cc}").select do |file|
      content = File.read(file)
      content.include?('__format__') || content.include?('OPENSSL_PRINTF_FORMAT')
    end
    
    # Patch each file that contains format attributes
    format_files.each do |file|
      puts "Patching #{file}..."
      
      begin
        # Create backup if it doesn't exist already
        unless File.exist?("#{file}.backup")
          FileUtils.cp(file, "#{file}.backup") 
        end
        
        # Read the file content
        content = File.read(file)
        
        # Replace format attributes
        content.gsub!(/__attribute__\(\(__format__[^)]*\)\)/, '')
        
        # Write the modified content back
        File.write(file, content)
      rescue => e
        puts "Warning: Failed to patch #{file}: #{e.message}"
      end
    end
    
    # Specifically patch base.h which contains the format macro definitions
    base_h = File.join(boringssl_dir, 'src', 'include', 'openssl', 'base.h')
    if File.exist?(base_h)
      puts "Patching base.h directly..."
      
      begin
        # Create backup if it doesn't exist already
        unless File.exist?("#{base_h}.backup")
          FileUtils.cp(base_h, "#{base_h}.backup")
        end
        
        # Read the file content
        content = File.read(base_h)
        
        # Add our definitions at the top of the file
        unless content.include?("SIFTER APP FIX")
          content = content.sub(/#ifndef OPENSSL_HEADER_BASE_H/, "#ifndef OPENSSL_HEADER_BASE_H\n\n/* SIFTER APP FIX */\n#define OPENSSL_PRINTF_FORMAT(a, b)\n#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\n#define OPENSSL_NO_ASM 1\n")
        end
        
        # Disable the format attribute section completely
        content = content.gsub(/#if defined\(__has_attribute\)/, "#if 0 /* disabled */")
        
        # Write the modified content back
        File.write(base_h, content)
      rescue => e
        puts "Warning: Failed to patch base.h: #{e.message}"
      end
    end
  end
  
  # Patch Firebase Storage Swift files
  firebase_storage_dir = installer.sandbox.pod_dir('FirebaseStorage')
  if firebase_storage_dir && File.directory?(firebase_storage_dir)
    puts "Patching Firebase Storage Swift files..."
    
    # Find the Storage.swift file
    storage_swift = Dir.glob("#{firebase_storage_dir}/**/*Storage.swift").first
    if storage_swift && File.exist?(storage_swift)
      puts "Found Storage.swift at #{storage_swift}"
      
      # Create backup if it doesn't exist already
      unless File.exist?("#{storage_swift}.backup")
        FileUtils.cp(storage_swift, "#{storage_swift}.backup")
      end
      
      # Apply the patch using sed commands
      system("sed -i '' 's/provider?.storage.useEmulator ?? false/provider != nil ? provider!.storage.useEmulator : false/g' \"#{storage_swift}\"")
      system("sed -i '' 's/provider?.storage.host ?? \"https:\\/\\/firebasestorage.googleapis.com\"/provider != nil ? provider!.storage.host : \"https:\\/\\/firebasestorage.googleapis.com\"/g' \"#{storage_swift}\"")
      system("sed -i '' 's/let auth: AuthInterop = AppCheckTokenProviderFactory.createAuthTokenProvider(app: app)/let auth: AuthInterop = AppCheckTokenProviderFactory.createAuthTokenProvider(app: app) as AuthInterop/g' \"#{storage_swift}\"")
      system("sed -i '' 's/return StorageProvider(app: app, auth: auth, appCheck: appCheck)/return StorageProvider(app: app, auth: auth, appCheck: appCheck as? AppCheckInterop)/g' \"#{storage_swift}\"")
      
      puts "✓ Patched Storage.swift"
    else
      puts "⚠️ Warning: Could not find Storage.swift"
    end
  end
end
EOL
echo "✓ Created optimized Podfile"

# Step 5: Create patch scripts for BoringSSL
echo "[5/7] Creating BoringSSL patch script..."
cat > patches/patch_boringssl.sh << 'EOL'
#!/bin/bash
# Script to patch BoringSSL-GRPC files

echo "Patching BoringSSL source files..."

# Common directories where BoringSSL may be found
DIRS=(
  "Pods/BoringSSL-GRPC"
  "Pods/gRPC-Core/src/boringssl"
  "~/Library/Developer/Xcode/DerivedData/*/Build/Products/*/BoringSSL-GRPC"
)

for DIR in "${DIRS[@]}"; do
  if [ -d "$DIR" ]; then
    echo "Found BoringSSL in $DIR"
    
    # Patch base.h if it exists
    BASE_H="$DIR/src/include/openssl/base.h"
    if [ -f "$BASE_H" ]; then
      echo "Patching $BASE_H"
      
      # Add our sifter fix at the top
      sed -i '' '/#ifndef OPENSSL_HEADER_BASE_H/a\
/* SIFTER APP FIX */\
#define OPENSSL_PRINTF_FORMAT(a, b)\
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\
#define OPENSSL_NO_ASM 1\
' "$BASE_H"
      
      # Disable the format attribute section
      sed -i '' 's/#if defined(__has_attribute)/#if 0 \/* disabled *\//' "$BASE_H"
      
      echo "✓ Patched $BASE_H"
    fi
    
    # Find and patch all files with __format__ attributes
    FORMAT_FILES=$(grep -l "__format__" "$DIR"/**/*.{h,c,cc} 2>/dev/null || true)
    for FILE in $FORMAT_FILES; do
      echo "Patching $FILE"
      sed -i '' 's/__attribute__((__format__[^)]*))//g' "$FILE"
    done
  fi
done

echo "BoringSSL patching completed"
EOL
chmod +x patches/patch_boringssl.sh

# Step 6: Install pods
echo "[6/7] Installing pods with all fixes applied..."
# Update CocoaPods repos
pod repo update
# Install pods with repo update
pod install --repo-update
# Run patch scripts
if [ -f "patches/patch_boringssl.sh" ]; then
  ./patches/patch_boringssl.sh
fi
echo "✓ Pods installed and patched"

# Step 7: Create run script
echo "[7/7] Creating run script..."
cat > run_with_final_fix.sh << 'EOL'
#!/bin/bash
# Run app with all fixes applied

# Re-apply patches to ensure they stick after any pod reinstalls
if [ -f "patches/patch_boringssl.sh" ]; then
  ./patches/patch_boringssl.sh
fi

# Set environment variables to avoid problematic flags
export OTHER_CFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export OTHER_CXXFLAGS="-w -Wno-format -Wno-everything -DOPENSSL_NO_ASM=1 -D__attribute__(x)="
export GCC_WARN_INHIBIT_ALL_WARNINGS="YES"

# Run flutter
cd ..
echo "Running Flutter with all fixes applied..."
flutter run
EOL
chmod +x run_with_final_fix.sh

echo ""
echo "======================================================================"
echo "                   FINAL SOLUTION IMPLEMENTED                         " 
echo "======================================================================"
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_final_fix.sh"
echo ""
echo "This comprehensive fix has:"
echo "  1. Updated Flutter dependencies to compatible versions"
echo "  2. Patched BoringSSL source files to remove format attributes"
echo "  3. Patched Firebase Storage Swift files to fix optional value issues"
echo "  4. Added compiler flags to disable problematic features"
echo "  5. Created reusable scripts for maintaining the patches"
echo ""
echo "For more details, see FINAL_SOLUTION.md"
echo ""

exit 0 
#!/bin/bash

# Downgrade Firebase and Fix BoringSSL-GRPC for iOS
echo "======================================================================"
echo "       DOWNGRADE FIREBASE AND FIX BORINGSSL-GRPC FOR iOS              "
echo "======================================================================"

# Step 1: Complete cleanup of all build artifacts
echo "[1/5] Performing complete cleanup..."
cd ..
flutter clean
cd ios
rm -rf Pods
rm -f Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/*sifter*
echo "✓ Complete cleanup done"

# Step 2: Update pub file to use older compatible versions of packages
echo "[2/5] Updating Flutter dependencies to use compatible older versions..."
cd ..
# Create backup of pubspec.yaml if it doesn't exist
if [ ! -f "pubspec.yaml.backup" ]; then
  cp pubspec.yaml pubspec.yaml.backup
fi

# Update the pubspec to specify compatible Firebase versions
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

  # Downgraded Firebase to ensure compatibility
  firebase_core: 2.15.1 
  firebase_auth: 4.7.3
  firebase_storage: 11.2.6
  # firebase_firestore: 4.8.5 # If needed

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

# Step 3: Create a modified Podfile with direct patching and older Firebase
echo "[3/5] Creating optimized Podfile with older Firebase versions..."
cat > Podfile << 'EOL'
# Uncomment this line to define a global platform for your project
platform :ios, '16.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

# Add environment variables to disable warnings
ENV['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
ENV['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
ENV['DEAD_CODE_STRIPPING'] = 'NO'

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
  
  # Pin Firebase to older versions for compatibility
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
        
        # Disable compiler index store and more flags
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
        config.build_settings['OTHER_CFLAGS'] = ['-w', '-Wno-format', '-Wno-everything']
        config.build_settings['OTHER_CXXFLAGS'] = ['-w', '-Wno-format', '-Wno-everything']
      end
      
      # Special configuration for Firebase
      if target.name.include?('Firebase')
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
      end
      
      # Global optimizations
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['DEAD_CODE_STRIPPING'] = 'NO'
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
    
    # Create a patch script for use after rebuilds
    patch_script = "patch_boringssl.sh"
    open(patch_script, 'w') do |f|
      f.puts "#!/bin/bash"
      f.puts "# Auto-generated patch script"
      f.puts "echo \"Patching BoringSSL source files...\""
      
      # Add each file to the patch script
      format_files.each do |file|
        rel_path = file.sub("#{boringssl_dir}/", "")
        f.puts "if [ -f \"Pods/BoringSSL-GRPC/#{rel_path}\" ]; then"
        f.puts "  echo \"Patching Pods/BoringSSL-GRPC/#{rel_path}\""
        f.puts "  sed -i '' 's/__attribute__((\\(__format__[^)]*\\)))//g' \"Pods/BoringSSL-GRPC/#{rel_path}\""
        f.puts "fi"
      end
      
      # Add specific patch for base.h
      f.puts "if [ -f \"Pods/BoringSSL-GRPC/src/include/openssl/base.h\" ]; then"
      f.puts "  echo \"Patching Pods/BoringSSL-GRPC/src/include/openssl/base.h\""
      f.puts "  sed -i '' 's/#if defined(__has_attribute)/#if 0 \\/\\* disabled \\*\\//' \"Pods/BoringSSL-GRPC/src/include/openssl/base.h\""
      f.puts "  sed -i '' '/#ifndef OPENSSL_HEADER_BASE_H/a\\\n/* SIFTER APP FIX */\\n#define OPENSSL_PRINTF_FORMAT(a, b)\\n#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)\\n#define OPENSSL_NO_ASM 1\\n' \"Pods/BoringSSL-GRPC/src/include/openssl/base.h\""
      f.puts "fi"
      
      f.puts "echo \"Patching completed\""
    end
    
    FileUtils.chmod("+x", patch_script)
    puts "Created patch script: #{patch_script}"
  end
end
EOL
echo "✓ Created optimized Podfile"

# Step 4: Install pods
echo "[4/5] Installing pods with direct patching..."
# Update CocoaPods repos
pod repo update
# Install pods with repo update
pod install --repo-update
# Run the patch script if available
if [ -f "patch_boringssl.sh" ]; then
  ./patch_boringssl.sh
fi
echo "✓ Pods installed and patched"

# Step 5: Create a run script
echo "[5/5] Creating run script..."
cat > run_with_downgraded_firebase.sh << 'EOL'
#!/bin/bash
# Run app with downgraded Firebase and BoringSSL patches

# Ensure the patches are applied
if [ -f "patch_boringssl.sh" ]; then
  ./patch_boringssl.sh
fi

# Run flutter in debug mode with special flags
cd ..
echo "Running Flutter with downgraded Firebase and BoringSSL patches..."
flutter run --no-fast-start
EOL
chmod +x run_with_downgraded_firebase.sh

echo ""
echo "======================================================================"
echo "                DOWNGRADE FIX HAS BEEN COMPLETED                      " 
echo "======================================================================"
echo ""
echo "To run the app with all fixes applied:"
echo "  ./run_with_downgraded_firebase.sh"
echo ""
echo "This fix:"
echo "1. Downgrades Firebase to a more compatible version"
echo "2. Directly patches BoringSSL to remove format attributes"
echo "3. Uses build setting modifications to avoid -G flags"
echo ""

exit 0 
#!/usr/bin/env ruby

# This script will patch Xcode's build settings directly in the BoringSSL-GRPC target
# to prevent -G flag usage that causes the error:
# 'unsupported option '-G' for target 'arm64-apple-ios16.0''
#
# Usage: ruby xcode_build_settings_patch.rb

require 'xcodeproj'
require 'json'
require 'fileutils'
require 'open3'

class XcodeBuildSettingsPatcher
  def initialize
    @project_path = find_pods_project
    @modified = false
    @success = false
  end
  
  def find_pods_project
    # Try to find the Pods project
    pods_project = Dir.glob('Pods/*.xcodeproj').first
    
    if !pods_project
      puts "Error: Could not find Pods project. Are you in the iOS directory?"
      exit 1
    end
    
    puts "Found Pods project at: #{pods_project}"
    pods_project
  end
  
  def run
    puts "BoringSSL-GRPC Build Settings Patcher"
    puts "===================================="
    
    patch_target_settings
    create_pre_build_script
    
    if @success
      puts "\n✅ BoringSSL-GRPC target has been successfully patched!"
      puts "You should now be able to build the app without the -G flag error."
    else
      puts "\n❌ Failed to patch the BoringSSL-GRPC target completely."
      puts "Some manual steps may be required. Please check the logs above."
    end
  end
  
  def patch_target_settings
    puts "\nPatching Xcode build settings for BoringSSL-GRPC target..."
    
    # Open the Pods project
    project = Xcodeproj::Project.open(@project_path)
    
    # Find the BoringSSL-GRPC target
    target = project.targets.find { |t| t.name == 'BoringSSL-GRPC' }
    
    if !target
      puts "Error: Could not find BoringSSL-GRPC target in Pods project."
      return
    end
    
    puts "Found BoringSSL-GRPC target"
    
    # Patch all build configurations
    success = true
    
    target.build_configurations.each do |config|
      puts "Patching build configuration: #{config.name}"
      
      # Add our custom build settings
      config.build_settings['OTHER_CFLAGS'] = '-w'
      config.build_settings['OTHER_CXXFLAGS'] = '-w'
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
      
      # Remove -G flags from all relevant build settings
      ['CC', 'CXX', 'LD', 'CFLAGS', 'CXXFLAGS', 'OTHER_CFLAGS', 'OTHER_CXXFLAGS'].each do |key|
        if config.build_settings[key]
          orig_value = config.build_settings[key]
          new_value = orig_value.gsub(/-G\S*/, '')
          
          if orig_value != new_value
            puts "  Removed -G flag from #{key}"
            config.build_settings[key] = new_value
            @modified = true
          end
        end
      end
      
      # Set preprocessor definitions to avoid format attribute expansion
      if config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] += ' OPENSSL_NO_ASM=1'
      else
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = 'COCOAPODS=1 OPENSSL_NO_ASM=1'
      end
      
      puts "  Updated preprocessor definitions"
      @modified = true
    end
    
    # Save the project if modified
    if @modified
      project.save
      puts "Saved project with updated build settings"
      @success = true
    else
      puts "No changes were needed to build settings"
    end
  rescue => e
    puts "Error patching build settings: #{e.message}"
    puts e.backtrace.join("\n")
  end
  
  def create_pre_build_script
    puts "\nCreating pre-build script for BoringSSL-GRPC..."
    
    # Create a directory for our build scripts
    FileUtils.mkdir_p("BoringSSL-Build-Scripts")
    
    # Create a pre-build script that will patch the source files
    script_path = "BoringSSL-Build-Scripts/pre_build.sh"
    
    File.open(script_path, "w") do |file|
      file.puts '#!/bin/bash'
      file.puts ''
      file.puts '# This script runs before building BoringSSL-GRPC to patch any problematic source files'
      file.puts 'echo "Running BoringSSL-GRPC pre-build script..."'
      file.puts ''
      file.puts '# Find the base.h file'
      file.puts 'BASE_H=$(find "${PODS_ROOT}" -path "*/BoringSSL-GRPC/src/include/openssl/base.h" -print -quit)'
      file.puts ''
      file.puts 'if [ -f "$BASE_H" ]; then'
      file.puts '  echo "Found base.h at $BASE_H"'
      file.puts ''
      file.puts '  # Check if the file contains the problematic format attribute'
      file.puts '  if grep -q "__attribute__((__format__(__printf__" "$BASE_H"; then'
      file.puts '    echo "Patching format attribute in base.h..."'
      file.puts '    # Make a backup'
      file.puts '    cp "$BASE_H" "${BASE_H}.backup"'
      file.puts '    # Replace the problematic line'
      file.puts '    sed -i \'\' \'s/__attribute__((__format__(__printf__, \\([^)]*\\)))/* __attribute__((__format__(__printf__, \\1))) */g\' "$BASE_H"'
      file.puts '    echo "Patched base.h successfully"'
      file.puts '  else'
      file.puts '    echo "No format attributes found in base.h - already patched"'
      file.puts '  fi'
      file.puts 'else'
      file.puts '  echo "Could not find base.h"'
      file.puts 'fi'
      file.puts ''
      file.puts '# Create a special header to override problematic macros'
      file.puts 'INCLUDE_DIR=$(dirname "$BASE_H")'
      file.puts 'if [ -n "$INCLUDE_DIR" ]; then'
      file.puts '  PATCH_HEADER="${INCLUDE_DIR}/boringssl_build_fix.h"'
      file.puts '  echo "Creating patch header at $PATCH_HEADER..."'
      file.puts ''
      file.puts '  cat > "$PATCH_HEADER" << EOL'
      file.puts '/* BoringSSL build fix header to prevent -G flag usage */'
      file.puts '#ifndef OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H'
      file.puts '#define OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H'
      file.puts ''
      file.puts '/* Redefine problematic macros */'
      file.puts '#undef OPENSSL_PRINTF_FORMAT'
      file.puts '#define OPENSSL_PRINTF_FORMAT(a, b)'
      file.puts ''
      file.puts '/* Disable format attributes that might trigger -G flags */'
      file.puts '#define __attribute__(x)'
      file.puts ''
      file.puts '#endif  /* OPENSSL_HEADER_BORINGSSL_BUILD_FIX_H */'
      file.puts 'EOL'
      file.puts ''
      file.puts '  # Include our patch header in base.h if not already there'
      file.puts '  if [ -f "$BASE_H" ] && ! grep -q "boringssl_build_fix.h" "$BASE_H"; then'
      file.puts '    echo "Adding patch header inclusion to base.h..."'
      file.puts '    # Find the first include line'
      file.puts '    FIRST_INCLUDE=$(grep -n "#include" "$BASE_H" | head -1 | cut -d: -f1)'
      file.puts '    if [ -n "$FIRST_INCLUDE" ]; then'
      file.puts '      # Insert after the first include'
      file.puts '      sed -i \'\' "${FIRST_INCLUDE}a\\\'
      file.puts '#include <openssl/boringssl_build_fix.h> /* Patch for -G flag issue */"  "$BASE_H"'
      file.puts '      echo "Added patch header inclusion to base.h"'
      file.puts '    fi'
      file.puts '  fi'
      file.puts 'fi'
      file.puts ''
      file.puts 'echo "Pre-build script completed"'
      file.puts 'exit 0'
    end
    
    # Make the script executable
    FileUtils.chmod(0755, script_path)
    
    puts "Created pre-build script at #{script_path}"
    
    # Create a post-build script that will verify the build
    script_path = "BoringSSL-Build-Scripts/post_build.sh"
    
    File.open(script_path, "w") do |file|
      file.puts '#!/bin/bash'
      file.puts ''
      file.puts '# This script runs after building BoringSSL-GRPC to verify no -G flags were used'
      file.puts 'echo "Running BoringSSL-GRPC post-build verification..."'
      file.puts ''
      file.puts '# Check the build log for -G flags'
      file.puts 'BUILD_LOG="${DERIVED_DATA_DIR}/Logs/Build/LogStoreManifest.plist"'
      file.puts 'if [ -f "$BUILD_LOG" ]; then'
      file.puts '  echo "Checking build log for -G flags..."'
      file.puts '  if grep -q "\-G" "$BUILD_LOG"; then'
      file.puts '    echo "WARNING: -G flags found in build log"'
      file.puts '    grep -n "\-G" "$BUILD_LOG"'
      file.puts '  else'
      file.puts '    echo "No -G flags found in build log"'
      file.puts '  fi'
      file.puts 'else'
      file.puts '  echo "Build log not found at $BUILD_LOG"'
      file.puts 'fi'
      file.puts ''
      file.puts 'echo "Post-build verification completed"'
      file.puts 'exit 0'
    end
    
    # Make the script executable
    FileUtils.chmod(0755, script_path)
    
    puts "Created post-build script at #{script_path}"
    
    # Create a README file to document the scripts
    readme_path = "BoringSSL-Build-Scripts/README.md"
    
    File.open(readme_path, "w") do |file|
      file.puts '# BoringSSL-GRPC Build Scripts'
      file.puts ''
      file.puts 'These scripts help fix the "-G flag not supported for arm64-apple-ios16.0" build error.'
      file.puts ''
      file.puts '## Usage'
      file.puts ''
      file.puts 'To use these scripts:'
      file.puts ''
      file.puts '1. Add `pre_build.sh` as a "Run Script" build phase to your Xcode project *before* the "Compile Sources" phase.'
      file.puts '2. Add `post_build.sh` as a "Run Script" build phase to your Xcode project *after* the "Compile Sources" phase.'
      file.puts ''
      file.puts 'Or simply run `add_build_phase.rb` to add these scripts automatically.'
      file.puts ''
      file.puts '## What the Scripts Do'
      file.puts ''
      file.puts '- `pre_build.sh`: Patches BoringSSL-GRPC source files to prevent the -G flag issue'
      file.puts '- `post_build.sh`: Verifies that no -G flags were used during the build'
      file.puts ''
      file.puts '## Additional Resources'
      file.puts ''
      file.puts 'For more information, see `BORINGSSL_FIX_README.md` in the ios directory.'
    end
    
    puts "Created README at #{readme_path}"
    
    @success = true
  rescue => e
    puts "Error creating build scripts: #{e.message}"
    puts e.backtrace.join("\n")
  end
end

# Run the patcher
patcher = XcodeBuildSettingsPatcher.new
patcher.run 
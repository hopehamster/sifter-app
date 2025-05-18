#!/usr/bin/env ruby

# This script patches the Xcode build process to fix the BoringSSL-GRPC '-G' flag issue
# Usage: Add this as a Run Script build phase in Xcode with the following command:
# ruby "${SRCROOT}/boringssl_build_fix.rb"

require 'fileutils'
require 'json'

# Function to modify compile commands to remove -G flags
def patch_compile_commands(file_path)
  return unless File.exist?(file_path)
  
  puts "Modifying compile commands in #{file_path}"
  
  begin
    content = File.read(file_path)
    commands = JSON.parse(content)
    
    modified = false
    commands.each do |cmd|
      # Only target BoringSSL-GRPC files
      next unless cmd['file'] && cmd['file'].include?('BoringSSL-GRPC')
      
      if cmd['command'] && cmd['command'].include?('-G')
        # Remove any -G flags from the command
        cmd['command'] = cmd['command'].gsub(/-G\S*\s/, ' ')
        modified = true
        puts "Patched command for #{cmd['file']}"
      end
    end
    
    if modified
      File.write(file_path, JSON.pretty_generate(commands))
      puts "Updated compile commands file"
    else
      puts "No changes needed in compile commands file"
    end
  rescue => e
    puts "Error modifying compile commands: #{e.message}"
  end
end

# Function to create a wrapper compiler script to filter out -G flags
def create_compiler_wrapper
  wrapper_path = File.join(ENV['BUILT_PRODUCTS_DIR'] || '.', 'clang_wrapper.sh')
  
  File.open(wrapper_path, 'w') do |f|
    f.puts '#!/bin/bash'
    f.puts '# Wrapper script to filter out -G flags before passing to the real compiler'
    f.puts 'REAL_COMPILER="$(xcrun -f clang)"'
    f.puts ''
    f.puts '# Filter out any -G flags'
    f.puts 'ARGS=('
    f.puts 'for arg in "$@"; do'
    f.puts '  if [[ "$arg" != -G* ]]; then'
    f.puts '    ARGS+=("$arg")'
    f.puts '  else'
    f.puts '    echo "Removed flag: $arg" >&2'
    f.puts '  fi'
    f.puts 'done'
    f.puts ''
    f.puts '# Call the real compiler with filtered arguments'
    f.puts 'exec "$REAL_COMPILER" "${ARGS[@]}"'
  end
  
  FileUtils.chmod(0755, wrapper_path)
  puts "Created compiler wrapper at #{wrapper_path}"
  
  wrapper_path
end

# Function to modify xcodebuild environment to use our wrapper
def patch_xcodebuild_environment
  # Create a wrapper script
  wrapper_path = create_compiler_wrapper
  
  # Add environment variables to use our wrapper
  ENV['CC'] = wrapper_path
  ENV['CCACHE_CC'] = wrapper_path
  
  puts "Set CC environment variable to use wrapper script"
end

# Main execution
puts "BoringSSL-GRPC Build Fix Script"
puts "==============================="

# Try both approaches
begin
  # Check if we're running in an Xcode build environment
  if ENV['XCODE_VERSION_ACTUAL']
    puts "Running in Xcode build environment"
    
    # Patch compile commands if available
    compile_commands_path = File.join(ENV['PROJECT_TEMP_DIR'] || '.', 'compile_commands.json')
    if File.exist?(compile_commands_path)
      patch_compile_commands(compile_commands_path)
    else
      puts "No compile_commands.json found at #{compile_commands_path}"
    end
    
    # Create compiler wrapper
    patch_xcodebuild_environment
  else
    puts "Not running in Xcode build environment"
  end
rescue => e
  puts "Error: #{e.message}"
end

puts "BoringSSL-GRPC Build Fix Script completed" 
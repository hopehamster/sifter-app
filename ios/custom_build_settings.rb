require 'xcodeproj'

# Custom build settings to work around the -G flag issue in BoringSSL-GRPC
module CustomBuildSettings
  def self.apply_to_project(project_path)
    # First check if the project file exists
    unless File.exist?(project_path)
      puts "Project file does not exist at #{project_path}, skipping custom build settings"
      return
    end
    
    project = Xcodeproj::Project.open(project_path)
    
    # Find the BoringSSL-GRPC target
    boring_ssl_target = project.native_targets.find { |target| target.name == 'BoringSSL-GRPC' }
    
    if boring_ssl_target
      puts "Found BoringSSL-GRPC target, applying custom build settings..."
      
      # Apply custom build settings to all configurations
      boring_ssl_target.build_configurations.each do |config|
        # Remove -G flags from any build settings
        config.build_settings.each do |key, value|
          if value.is_a?(String) && value.include?('-G')
            config.build_settings[key] = value.gsub(/-G\S*/, '')
            puts "Removed -G flag from #{key} in #{config.name}"
          elsif value.is_a?(Array)
            config.build_settings[key] = value.map { |v| v.is_a?(String) ? v.gsub(/-G\S*/, '') : v }
          end
        end
        
        # Set specific flags that are known to work
        config.build_settings['OTHER_CFLAGS'] = '-w'
        config.build_settings['OTHER_CXXFLAGS'] = '-w'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
        config.build_settings['COMPILER_INDEX_STORE_ENABLE'] = 'NO'
      end
      
      # Save the project
      project.save
      puts "Applied custom build settings to BoringSSL-GRPC target"
    else
      puts "Could not find BoringSSL-GRPC target in project"
    end
  end
end 
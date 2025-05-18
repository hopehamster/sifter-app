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

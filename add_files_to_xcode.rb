#!/usr/bin/env ruby

# Script to programmatically add new Swift files to Xcode project
# This allows claude-code to complete the integration without GUI access

require 'xcodeproj'

project_path = 'iOS/Flirrt.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.first

# Find the Views group in the Flirrt main group
flirrt_group = project.main_group.find_subpath('Flirrt', false)
views_group = flirrt_group.find_subpath('Views', false)

# New files to add (just filenames, since we'll use relative paths from Views group)
new_files = [
  'EnhancedScreenshotAnalysisView.swift',
  'ModernOnboardingView.swift',
  'MultiScreenshotPicker.swift',
  'VoicePlaybackView.swift'
]

new_files.each do |file_name|
  # Check if file already exists in project
  existing_file = views_group.files.find { |f| f.path == file_name }

  if existing_file
    puts "✓ #{file_name} already in project"
  else
    # Add file reference to Views group (just the filename, relative to Views group)
    file_ref = views_group.new_reference(file_name)

    # Add file to target's sources build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "✓ Added #{file_name} to project and target"
  end
end

# Save the project
project.save

puts "\n✅ All files added successfully!"
puts "Next: Build the project with 'xcodebuild -project #{project_path} -scheme Flirrt -configuration Debug'"


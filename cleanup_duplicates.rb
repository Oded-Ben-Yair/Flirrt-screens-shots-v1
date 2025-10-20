#!/usr/bin/env ruby

# Script to remove duplicate file references from Xcode project

require 'xcodeproj'

project_path = 'iOS/Flirrt.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.first

# Find the Views group
flirrt_group = project.main_group.find_subpath('Flirrt', false)
views_group = flirrt_group.find_subpath('Views', false)

# Files to check for duplicates
file_names = [
  'EnhancedScreenshotAnalysisView.swift',
  'ModernOnboardingView.swift',
  'MultiScreenshotPicker.swift',
  'VoicePlaybackView.swift'
]

file_names.each do |file_name|
  # Find all file references with this name
  all_refs = views_group.files.select { |f| f.path&.include?(file_name) }

  if all_refs.length > 1
    puts "Found #{all_refs.length} references for #{file_name}, cleaning up duplicates..."

    # Keep only the one with simple relative path (not iOS/Flirrt/Views/...)
    correct_ref = all_refs.find { |f| f.path == file_name }
    incorrect_refs = all_refs.reject { |f| f.path == file_name }

    incorrect_refs.each do |ref|
      puts "  Removing duplicate: #{ref.path}"

      # Remove from build phases
      target.source_build_phase.files.each do |build_file|
        if build_file.file_ref == ref
          build_file.remove_from_project
        end
      end

      # Remove file reference
      ref.remove_from_project
    end

    puts "  ✓ Kept correct reference: #{correct_ref.path}"
  else
    puts "✓ #{file_name} has no duplicates"
  end
end

# Save the project
project.save

puts "\n✅ Cleanup complete!"
puts "Run: xcodebuild -project #{project_path} -scheme Flirrt -configuration Debug"

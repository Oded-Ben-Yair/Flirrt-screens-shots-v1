#!/usr/bin/env ruby
# Script to add Swift files to Xcode target using xcodeproj gem
# Usage: ruby scripts/add-to-xcode-target.rb

require 'xcodeproj'

# Configuration
PROJECT_PATH = 'iOS/Flirrt.xcodeproj'
TARGET_NAME = 'Flirrt'
FILES_TO_ADD = [
  'iOS/Flirrt/Services/ScreenshotDetectionManager.swift',
  'iOS/Flirrt/Services/DarwinNotificationManager.swift'
]

puts "🔧 Xcode Target Automation Script"
puts "================================="
puts "Project: #{PROJECT_PATH}"
puts "Target: #{TARGET_NAME}"
puts "Files to add: #{FILES_TO_ADD.count}"
puts ""

# Load the project
puts "📂 Loading Xcode project..."
project = Xcodeproj::Project.open(PROJECT_PATH)

# Find the target
puts "🎯 Finding target '#{TARGET_NAME}'..."
target = project.targets.find { |t| t.name == TARGET_NAME }

if target.nil?
  puts "❌ Error: Target '#{TARGET_NAME}' not found"
  puts "Available targets: #{project.targets.map(&:name).join(', ')}"
  exit 1
end

puts "✅ Found target: #{target.name}"

# Find the Services group
puts "📁 Finding Services group..."
services_group = project.main_group.find_subpath('Flirrt/Services', true)

if services_group.nil?
  puts "❌ Error: Services group not found"
  exit 1
end

puts "✅ Found Services group"

# Add each file
FILES_TO_ADD.each do |file_path|
  file_name = File.basename(file_path)

  # Check if file already exists in project
  existing_file = project.files.find { |f| f.path == file_path }

  if existing_file
    puts "⏭️  #{file_name} already in project, checking target membership..."
    file_ref = existing_file
  else
    puts "➕ Adding #{file_name} to project..."
    file_ref = services_group.new_reference(file_path)
  end

  # Check if already in target
  if target.source_build_phase.files.any? { |f| f.file_ref == file_ref }
    puts "   ✅ #{file_name} already in target #{TARGET_NAME}"
  else
    puts "   📎 Adding #{file_name} to target #{TARGET_NAME}..."
    target.add_file_references([file_ref])
    puts "   ✅ #{file_name} added to target"
  end
end

# Save the project
puts ""
puts "💾 Saving project..."
project.save

puts "✅ Done! Files successfully added to Xcode target"
puts ""
puts "Next steps:"
puts "1. Verify in Xcode: File > Project > Flirrt > Build Phases > Compile Sources"
puts "2. Run: xcodebuild -scheme Flirrt clean build"

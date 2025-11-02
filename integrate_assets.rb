#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'iOS/Flirrt.xcodeproj'
target_name = 'Flirrt'
asset_catalog_path = 'iOS/Flirrt/Assets.xcassets'

puts "Opening project: #{project_path}"
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == target_name }
if target.nil?
  puts "❌ Error: Target '#{target_name}' not found."
  puts "Available targets:"
  project.targets.each { |t| puts "  - #{t.name}" }
  exit 1
end

puts "Found target: #{target.name}"

# Find or create the Flirrt group
group = project.main_group.find_subpath('Flirrt', true)
if group.nil?
  puts "❌ Error: Could not find or create 'Flirrt' group"
  exit 1
end

# Check if Assets.xcassets already exists in project
existing_ref = group.files.find { |f| f.path == 'Assets.xcassets' }

if existing_ref.nil?
  puts "Adding Assets.xcassets to project..."
  file_ref = group.new_file(asset_catalog_path)
  
  # Add to resources build phase
  target.resources_build_phase.add_file_reference(file_ref)
  puts "✅ Added Assets.xcassets to resources"
else
  puts "✅ Assets.xcassets already in project"
end

# Set the build setting to use AppIcon
puts "Setting ASSETCATALOG_COMPILER_APPICON_NAME..."
target.build_configurations.each do |config|
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  puts "  ✅ #{config.name}: AppIcon"
end

# Save the project
project.save
puts "✅ Project file updated successfully"

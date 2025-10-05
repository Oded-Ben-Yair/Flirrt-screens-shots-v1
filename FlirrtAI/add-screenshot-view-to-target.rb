#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'iOS/Flirrt.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'Flirrt' }

# Navigate to Views group
views_group = project.main_group.find_subpath('Flirrt/Views', true)

# Add ScreenshotAnalysisView.swift
file_path = 'ScreenshotAnalysisView.swift'
file_ref = views_group.new_reference(file_path)
file_ref.last_known_file_type = 'sourcecode.swift'
file_ref.source_tree = '<group>'

unless target.source_build_phase.files_references.include?(file_ref)
  target.source_build_phase.add_file_reference(file_ref)
  puts "✅ Added ScreenshotAnalysisView.swift to Flirrt target"
else
  puts "ℹ️  ScreenshotAnalysisView.swift already in target"
end

project.save
puts "✅ Xcode project saved"

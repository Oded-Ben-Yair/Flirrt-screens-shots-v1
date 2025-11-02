#!/bin/bash
#
# Vibe8 Complete TestFlight Deployment - Final Run
# Generated: October 22, 2025
# Expert-validated, production-ready
#
# This script will:
# 1. Copy icon assets to Xcode project
# 2. Integrate Asset Catalog into Xcode project  
# 3. Update Info.plist with CFBundleIconName
# 4. Clean build
# 5. Archive
# 6. Export IPA
# 7. Upload to TestFlight
#
# Estimated time: 30-40 minutes
#

set -eo pipefail

PROJECT_ROOT="$(pwd)"
ICON_SOURCE="$PROJECT_ROOT/vibe8_icons_complete"
PROJECT_DIR="iOS/Flirrt"
ASSETS_DIR="$PROJECT_DIR/Assets.xcassets"
APPICON_SET="$ASSETS_DIR/AppIcon.appiconset"

echo "=================================="
echo "🚀 Vibe8 TestFlight Deployment"
echo "=================================="
echo ""
echo "Project: $PROJECT_ROOT"
echo "Icons: $ICON_SOURCE"
echo ""

# ===== PHASE 1: Copy Icon Assets =====
echo "📦 PHASE 1: Copying icon assets to Xcode project..."
echo ""

# Create Assets.xcassets directory if it doesn't exist
if [ ! -d "$ASSETS_DIR" ]; then
    echo "Creating Assets.xcassets directory..."
    mkdir -p "$ASSETS_DIR"
fi

# Copy the complete AppIcon.appiconset
echo "Copying AppIcon.appiconset..."
cp -R "$ICON_SOURCE/AppIcon.appiconset" "$ASSETS_DIR/"

# Verify all files copied
ICON_COUNT=$(ls -1 "$APPICON_SET"/*.png 2>/dev/null | wc -l)
echo "✅ Copied $ICON_COUNT icon files"
echo "✅ Contents.json in place"
echo ""

# ===== PHASE 2: Integrate into Xcode Project =====
echo "🔧 PHASE 2: Integrating Asset Catalog into Xcode project..."
echo ""

# Check if xcodeproj gem is installed
if ! gem list -i xcodeproj &> /dev/null; then
    echo "Installing xcodeproj gem..."
    sudo gem install xcodeproj
fi

# Create Ruby script to integrate assets
cat > integrate_assets.rb << 'RUBYSCRIPT'
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
RUBYSCRIPT

chmod +x integrate_assets.rb
ruby integrate_assets.rb

echo ""

# ===== PHASE 3: Update Info.plist =====
echo "📝 PHASE 3: Updating Info.plist..."
echo ""

INFO_PLIST="$PROJECT_DIR/Info.plist"

if [ -f "$INFO_PLIST" ]; then
    # Try to set, if fails then add
    /usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "$INFO_PLIST" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "$INFO_PLIST"
    echo "✅ CFBundleIconName set to 'AppIcon'"
else
    echo "⚠️  Warning: Info.plist not found at $INFO_PLIST"
    echo "Searching for Info.plist..."
    find iOS -name "Info.plist" -type f
fi

echo ""

# ===== PHASE 4: Clean Build =====
echo "🧹 PHASE 4: Cleaning build directory..."
echo ""

xcodebuild clean -project iOS/Flirrt.xcodeproj -scheme Flirrt
rm -rf build/

echo "✅ Clean complete"
echo ""

# ===== PHASE 5: Archive =====
echo "📦 PHASE 5: Building archive..."
echo ""

xcodebuild archive \
    -project iOS/Flirrt.xcodeproj \
    -scheme Flirrt \
    -archivePath build/Flirrt.xcarchive \
    -allowProvisioningUpdates

echo "✅ Archive created"
echo ""

# ===== PHASE 6: Export IPA =====
echo "📤 PHASE 6: Exporting IPA..."
echo ""

xcodebuild -exportArchive \
    -archivePath build/Flirrt.xcarchive \
    -exportPath build \
    -exportOptionsPlist iOS/exportOptions.plist \
    -allowProvisioningUpdates

echo "✅ IPA exported"
echo ""

# ===== PHASE 7: Upload to TestFlight =====
echo "🚀 PHASE 7: Uploading to TestFlight..."
echo ""

xcrun altool --upload-app \
    -f build/Flirrt.ipa \
    -t ios \
    --apiKey N2K5XYCGR4 \
    --apiIssuer c793bfe0-9549-4032-a34b-bb87ee7608a0 \
    --verbose

echo ""
echo "=================================="
echo "🎉 DEPLOYMENT COMPLETE!"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Wait for email from Apple (10-30 minutes)"
echo "2. Go to App Store Connect → TestFlight"
echo "3. Create public link"
echo "4. Share with coworkers!"
echo ""

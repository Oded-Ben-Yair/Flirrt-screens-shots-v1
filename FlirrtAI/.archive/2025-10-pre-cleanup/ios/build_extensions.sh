#!/bin/bash

# Build script for Flirrt iOS app with extensions
# This script helps build the app and extensions properly

set -e

echo "🚀 Building Flirrt iOS App with Extensions"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found. Please install Xcode."
    exit 1
fi

# Configuration
SCHEME="Flirrt"
CONFIGURATION="Debug"
DESTINATION="platform=iOS Simulator,name=iPhone 15"

echo "📱 Building for iOS Simulator..."

# Try to open in Xcode first since SPM has limitations with app extensions
echo "📦 Opening project in Xcode..."
xed .

echo "⚠️  Note: App extensions cannot be built directly with Swift Package Manager."
echo "   Please use Xcode to build and test the share extension."
echo ""
echo "🔧 Manual steps in Xcode:"
echo "   1. Add new 'Share Extension' target"
echo "   2. Name it 'FlirrtShare'"
echo "   3. Copy ShareViewController.swift to the new target"
echo "   4. Add Info.plist and entitlements"
echo "   5. Enable App Groups in both main app and extension"
echo ""
echo "📂 Files are ready at:"
echo "   - ShareViewController.swift: $SCRIPT_DIR/FlirrtShare/"
echo "   - Info.plist: $SCRIPT_DIR/FlirrtShare/Info.plist"
echo "   - Entitlements: $SCRIPT_DIR/FlirrtShare/FlirrtShare.entitlements"

exit 0
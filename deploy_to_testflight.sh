#!/bin/bash
# Flirrt.AI Autonomous TestFlight Deployment Script

set -eo pipefail

# --- Configuration ---
export APP_STORE_CONNECT_API_KEY_ID="R67DCD65GB"
export APP_STORE_CONNECT_API_ISSUER_ID="9b5e8cdd-7c88-4a26-b6f8-c9a6a8f0f9c9"
export PATH="/Users/macbookairm1/.gem/ruby/2.6.0/bin:$PATH"

PROJECT_PATH="iOS/Flirrt.xcodeproj"
SCHEME="Flirrt"
CONFIGURATION="Release"
ARCHIVE_PATH="build/Flirrt.xcarchive"
IPA_PATH="build"

# --- Script Start ---

echo "🚀 Starting Flirrt.AI TestFlight Deployment..."
echo "📅 $(date)"
echo ""

# 1. Clean previous builds
echo "🧹 Cleaning old build artifacts..."
rm -rf "${ARCHIVE_PATH}"
rm -rf "${IPA_PATH}/Flirrt.ipa"
rm -rf build/
mkdir -p build

# 2. Build and Archive
echo ""
echo "🏗️  Building and archiving the project..."
echo "   Project: ${PROJECT_PATH}"
echo "   Scheme: ${SCHEME}"
echo "   Configuration: ${CONFIGURATION}"
echo ""

if command -v xcpretty &> /dev/null; then
    xcodebuild -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -configuration "${CONFIGURATION}" \
               -archivePath "${ARCHIVE_PATH}" \
               clean archive | xcpretty
    BUILD_EXIT_CODE=${PIPESTATUS[0]}
else
    xcodebuild -project "${PROJECT_PATH}" \
               -scheme "${SCHEME}" \
               -configuration "${CONFIGURATION}" \
               -archivePath "${ARCHIVE_PATH}" \
               clean archive
    BUILD_EXIT_CODE=$?
fi

if [ $BUILD_EXIT_CODE -ne 0 ]; then
    echo "❌ Archive failed. Please check the logs above."
    exit 1
fi

echo ""
echo "✅ Archive successful!"

# 3. Export IPA
echo ""
echo "📦 Exporting IPA from archive..."

if command -v xcpretty &> /dev/null; then
    xcodebuild -exportArchive \
               -archivePath "${ARCHIVE_PATH}" \
               -exportPath "${IPA_PATH}" \
               -exportOptionsPlist "iOS/exportOptions.plist" | xcpretty
    EXPORT_EXIT_CODE=${PIPESTATUS[0]}
else
    xcodebuild -exportArchive \
               -archivePath "${ARCHIVE_PATH}" \
               -exportPath "${IPA_PATH}" \
               -exportOptionsPlist "iOS/exportOptions.plist"
    EXPORT_EXIT_CODE=$?
fi

if [ $EXPORT_EXIT_CODE -ne 0 ]; then
    echo "❌ IPA export failed. Please check the logs above."
    exit 1
fi

echo ""
echo "✅ IPA export successful!"

# 4. Upload to TestFlight
echo ""
echo "☁️  Uploading IPA to App Store Connect..."
echo "   This may take several minutes..."
echo ""

xcrun altool --upload-app \
             -f "${IPA_PATH}/Flirrt.ipa" \
             -t ios \
             --apiKey "${APP_STORE_CONNECT_API_KEY_ID}" \
             --apiIssuer "${APP_STORE_CONNECT_API_ISSUER_ID}"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ TestFlight upload failed. Please check the logs above."
    exit 1
fi

echo ""
echo "🎉 Successfully uploaded to App Store Connect!"
echo "📅 Completed at: $(date)"
echo ""
echo "⏳ The build is now processing with Apple (10-30 minutes)."
echo "📱 Once processing is complete, you can create a TestFlight public link."
echo ""

# --- End of Script ---

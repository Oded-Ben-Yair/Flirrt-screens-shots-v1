# Vibe8.AI - Autonomous TestFlight Deployment Guide

This guide provides a complete, autonomous workflow for building, signing, and uploading the Vibe8.AI iOS app to TestFlight. It is designed to be executed by an AI agent (claude-code) on a macOS environment.

---

## 🚀 Mission

**Goal:** Autonomously build, sign, and upload the Vibe8.AI app to TestFlight, providing the user with a public download link.

**Agent:** claude-code

**Environment:** macOS with Xcode, Homebrew, and Git installed.

---

## 📋 Phase 1: Prerequisites & Setup (15 minutes)

### Step 1.1: Request Secrets from User

First, you must request the following secrets from the user. **Do not proceed without them.**

```
I need the following secrets to automate the TestFlight deployment. Please provide them:

1.  **App Store Connect API Key ID:** (e.g., `A1B2C3D4E5`)
2.  **App Store Connect Issuer ID:** (e.g., `12345678-1234-1234-1234-1234567890ab`)
3.  **App Store Connect API Key (.p8 file content):** (The full content of the `AuthKey_XXXX.p8` file)

These are required for secure, automated uploads. See Apple's documentation for creating API keys if you haven't already.
```

### Step 1.2: Install Dependencies

Ensure `xcpretty` is installed for better logging.

```bash
gem install xcpretty
```

### Step 1.3: Create API Key File

Once the user provides the `.p8` file content, save it to a secure location.

```bash
mkdir -p ~/.appstoreconnect/private_keys
# Save the .p8 file content provided by the user to:
# ~/.appstoreconnect/private_keys/AuthKey_A1B2C3D4E5.p8
# (Replace A1B2C3D4E5 with the actual Key ID)
```

### Step 1.4: Create `exportOptions.plist`

Create the `exportOptions.plist` file in the `iOS/` directory of the project.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>  <!-- IMPORTANT: Request this from the user -->
    <key>uploadBitcode</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

**Action:** Request the `teamID` from the user and replace `YOUR_TEAM_ID`.

---

## 🚀 Phase 2: Autonomous Build & Upload (15 minutes)

Execute the following bash script from the root of the repository. It will clean, build, archive, and upload the app.

```bash
#!/bin/bash
# Vibe8.AI Autonomous TestFlight Deployment Script

set -eo pipefail

# --- Configuration ---
# These will be provided by the user in Phase 1
API_KEY_ID="${APP_STORE_CONNECT_API_KEY_ID}"
ISSUER_ID="${APP_STORE_CONNECT_API_ISSUER_ID}"

PROJECT_PATH="iOS/Flirrt.xcodeproj"
SCHEME="Flirrt"
CONFIGURATION="Release"
ARCHIVE_PATH="build/Flirrt.xcarchive"
IPA_PATH="build"

# --- Script Start ---

echo "🚀 Starting Vibe8.AI TestFlight Deployment..."

# 1. Clean previous builds
echo "🧹 Cleaning old build artifacts..."
rm -rf "${ARCHIVE_PATH}"
rm -rf "${IPA_PATH}/Flirrt.ipa"

# 2. Build and Archive
echo "🏗️ Building and archiving the project..."
xcodebuild -project "${PROJECT_PATH}" \
           -scheme "${SCHEME}" \
           -configuration "${CONFIGURATION}" \
           -archivePath "${ARCHIVE_PATH}" \
           clean archive | xcpretty

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ Archive failed. Please check the logs."
    exit 1
fi

echo "✅ Archive successful!"

# 3. Export IPA
echo "📦 Exporting IPA from archive..."
xcodebuild -exportArchive \
           -archivePath "${ARCHIVE_PATH}" \
           -exportPath "${IPA_PATH}" \
           -exportOptionsPlist "iOS/exportOptions.plist" | xcpretty

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "❌ IPA export failed. Please check the logs."
    exit 1
fi

echo "✅ IPA export successful!"

# 4. Upload to TestFlight
echo "☁️ Uploading IPA to App Store Connect..."

xcrun altool --upload-app \
             -f "${IPA_PATH}/Flirrt.ipa" \
             -t ios \
             --apiKey "${API_KEY_ID}" \
             --apiIssuer "${ISSUER_ID}"

if [ $? -ne 0 ]; then
    echo "❌ TestFlight upload failed. Please check the logs."
    exit 1
fi

echo "🎉 Successfully uploaded to App Store Connect!"
echo "The build will be available in TestFlight shortly."

# --- End of Script ---
```

---

## 🚀 Phase 3: Post-Upload & User Notification (5 minutes)

Once the upload is successful, you must notify the user with the next steps.

```
✅ **Build successfully uploaded to App Store Connect!**

The build is now processing. This can take anywhere from 10 to 30 minutes.

**What happens next:**

1.  **Apple Processing:** Apple will process the build. You can monitor the status in App Store Connect under the "TestFlight" tab.
2.  **Internal Testing:** Once processing is complete, the build will automatically be available to all internal testers (users with the "App Manager" or "Developer" role in your App Store Connect team).
3.  **External Testing (Get the Link):**
    *   Go to your app in App Store Connect.
    *   Navigate to the **TestFlight** tab.
    *   Create a **Public Link** for a testing group.
    *   **Share this link** with your coworkers.

**The TestFlight download link is now ready to be created and shared!** 🚀
```

---

## 📚 References & Best Practices

This guide was synthesized from expert advice provided by:
- **GPT-4O:** For Xcode project configuration and manual best practices.
- **Grok-4:** For the core `xcodebuild` automation script.
- **Gemini:** For detailed App Store Connect API key setup and security.

By following this guide, you will achieve a secure, repeatable, and autonomous deployment process.


#!/bin/bash
# Install New API Key and Upload to TestFlight

set -e

# New API credentials
API_KEY_ID="N2K5XYCGR4"
API_ISSUER_ID="c793bfe0-9549-4032-a34b-bb87ee7608a0"
API_KEY_FILE="AuthKey_${API_KEY_ID}.p8"

echo "🔐 Installing New API Key for TestFlight Upload"
echo ""
echo "API Key ID: ${API_KEY_ID}"
echo "Issuer ID: ${API_ISSUER_ID}"
echo ""

# Step 1: Check if .p8 file exists in Downloads
if [ ! -f ~/Downloads/"${API_KEY_FILE}" ]; then
    echo "❌ ERROR: API key file not found!"
    echo ""
    echo "Expected location: ~/Downloads/${API_KEY_FILE}"
    echo ""
    echo "Please download the .p8 file from App Store Connect:"
    echo "1. Go to: https://appstoreconnect.apple.com/access/api"
    echo "2. Find key: ${API_KEY_ID}"
    echo "3. Click 'Download API Key'"
    echo "4. Save to Downloads folder"
    echo ""
    echo "Then run this script again."
    exit 1
fi

echo "✅ Found API key file in Downloads"
echo ""

# Step 2: Create directory if it doesn't exist
echo "📁 Creating API keys directory..."
mkdir -p ~/.appstoreconnect/private_keys
echo "✅ Directory ready"
echo ""

# Step 3: Copy the new API key
echo "📋 Installing API key..."
cp ~/Downloads/"${API_KEY_FILE}" ~/.appstoreconnect/private_keys/
echo "✅ API key installed"
echo ""

# Step 4: Set proper permissions
echo "🔒 Setting permissions..."
chmod 600 ~/.appstoreconnect/private_keys/"${API_KEY_FILE}"
echo "✅ Permissions set (read-only)"
echo ""

# Step 5: Verify installation
echo "🔍 Verifying installation..."
if [ -f ~/.appstoreconnect/private_keys/"${API_KEY_FILE}" ]; then
    ls -lh ~/.appstoreconnect/private_keys/"${API_KEY_FILE}"
    echo "✅ Installation verified"
    echo ""
else
    echo "❌ Installation failed"
    exit 1
fi

# Step 6: Upload to TestFlight
echo "☁️  Uploading to TestFlight..."
echo "   This may take 2-5 minutes..."
echo ""

xcrun altool --upload-app \
             -f "build/Flirrt.ipa" \
             -t ios \
             --apiKey "${API_KEY_ID}" \
             --apiIssuer "${API_ISSUER_ID}" \
             --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 SUCCESS! Upload completed!"
    echo ""
    echo "Next steps:"
    echo "  1. Wait 10-30 minutes for Apple processing"
    echo "  2. Go to: https://appstoreconnect.apple.com/apps"
    echo "  3. Select 'Vibe8' → TestFlight tab"
    echo "  4. Once 'Ready to Test', enable External Testing"
    echo "  5. Create Public Link"
    echo "  6. Share link with coworkers"
    echo ""
else
    echo ""
    echo "❌ Upload failed!"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify API key has proper permissions (Admin or App Manager)"
    echo "  2. Check key hasn't been revoked"
    echo "  3. Try alternative upload method (see TESTFLIGHT_UPLOAD_ALTERNATIVES.md)"
    echo ""
    exit 1
fi

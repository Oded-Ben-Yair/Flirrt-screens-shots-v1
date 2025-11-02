#!/bin/bash
# Quick Upload Command - Run this after creating app in App Store Connect

echo "🚀 Uploading Flirrt.AI to TestFlight..."
echo ""
echo "Prerequisites:"
echo "  ✅ App created in App Store Connect with Bundle ID: flirrt.ai"
echo "  ✅ IPA ready at: build/Flirrt.ipa"
echo ""
echo "Starting upload..."
echo ""

xcrun altool --upload-app \
             -f "build/Flirrt.ipa" \
             -t ios \
             --apiKey "R67DCD65GB" \
             --apiIssuer "9b5e8cdd-7c88-4a26-b6f8-c9a6a8f0f9c9" \
             --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Upload successful!"
    echo ""
    echo "Next steps:"
    echo "  1. Wait 10-30 minutes for Apple processing"
    echo "  2. Go to: https://appstoreconnect.apple.com/apps"
    echo "  3. Select Flirrt.AI → TestFlight"
    echo "  4. Once 'Ready to Test', enable External Testing"
    echo "  5. Create Public Link"
    echo "  6. Share link with coworkers"
    echo ""
else
    echo ""
    echo "❌ Upload failed!"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Verify app exists at: https://appstoreconnect.apple.com/apps"
    echo "  2. Check Bundle ID matches: flirrt.ai"
    echo "  3. Verify API key permissions at: https://appstoreconnect.apple.com/access/api"
    echo "  4. If still failing, use Xcode Organizer or Transporter app"
    echo ""
fi

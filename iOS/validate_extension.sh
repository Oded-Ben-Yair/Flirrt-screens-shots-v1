#!/bin/bash

# Validation script for share extension configuration
# Checks if all required files and configurations are present

set -e

echo "🔍 Validating Share Extension Configuration"
echo "=========================================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SHARE_DIR="$SCRIPT_DIR/FlirrtShare"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validation functions
check_file() {
    if [ -f "$1" ]; then
        echo -e "✅ ${GREEN}Found:${NC} $1"
        return 0
    else
        echo -e "❌ ${RED}Missing:${NC} $1"
        return 1
    fi
}

check_plist_key() {
    local file="$1"
    local key="$2"
    if plutil -extract "$key" raw "$file" >/dev/null 2>&1; then
        echo -e "✅ ${GREEN}Found key:${NC} $key in $(basename "$file")"
        return 0
    else
        echo -e "❌ ${RED}Missing key:${NC} $key in $(basename "$file")"
        return 1
    fi
}

# Check required files
echo "📁 Checking Required Files:"
check_file "$SHARE_DIR/ShareViewController.swift"
check_file "$SHARE_DIR/Info.plist"
check_file "$SHARE_DIR/FlirrtShare.entitlements"

echo ""
echo "📋 Checking Info.plist Configuration:"

# Check Info.plist structure
if [ -f "$SHARE_DIR/Info.plist" ]; then
    check_plist_key "$SHARE_DIR/Info.plist" "NSExtension"
    check_plist_key "$SHARE_DIR/Info.plist" "NSExtension.NSExtensionPointIdentifier"
    check_plist_key "$SHARE_DIR/Info.plist" "NSExtension.NSExtensionPrincipalClass"
    check_plist_key "$SHARE_DIR/Info.plist" "NSExtension.NSExtensionAttributes"

    # Check specific values
    POINT_ID=$(plutil -extract "NSExtension.NSExtensionPointIdentifier" raw "$SHARE_DIR/Info.plist" 2>/dev/null || echo "")
    if [ "$POINT_ID" = "com.apple.share-services" ]; then
        echo -e "✅ ${GREEN}Correct extension point identifier${NC}"
    else
        echo -e "❌ ${RED}Wrong extension point identifier: $POINT_ID${NC}"
    fi

    PRINCIPAL_CLASS=$(plutil -extract "NSExtension.NSExtensionPrincipalClass" raw "$SHARE_DIR/Info.plist" 2>/dev/null || echo "")
    if [ "$PRINCIPAL_CLASS" = "ShareViewController" ]; then
        echo -e "✅ ${GREEN}Correct principal class${NC}"
    else
        echo -e "❌ ${RED}Wrong principal class: $PRINCIPAL_CLASS${NC}"
    fi
fi

echo ""
echo "🛡️ Checking Entitlements:"

if [ -f "$SHARE_DIR/FlirrtShare.entitlements" ]; then
    check_plist_key "$SHARE_DIR/FlirrtShare.entitlements" "com.apple.security.application-groups"

    # Check App Groups configuration
    APP_GROUPS=$(plutil -extract "com.apple.security.application-groups" json "$SHARE_DIR/FlirrtShare.entitlements" 2>/dev/null || echo "[]")
    if echo "$APP_GROUPS" | grep -q "group.com.flirrt.ai.shared"; then
        echo -e "✅ ${GREEN}App Groups configured correctly${NC}"
    else
        echo -e "❌ ${RED}App Groups missing or incorrect${NC}"
    fi
fi

echo ""
echo "🏗️ Checking Swift Code:"

if [ -f "$SHARE_DIR/ShareViewController.swift" ]; then
    if grep -q "class ShareViewController: UIViewController" "$SHARE_DIR/ShareViewController.swift"; then
        echo -e "✅ ${GREEN}ShareViewController inherits from UIViewController${NC}"
    else
        echo -e "❌ ${RED}ShareViewController inheritance incorrect${NC}"
    fi

    if grep -q "extensionContext" "$SHARE_DIR/ShareViewController.swift"; then
        echo -e "✅ ${GREEN}Extension context usage found${NC}"
    else
        echo -e "❌ ${RED}Extension context usage missing${NC}"
    fi

    if grep -q "group.com.flirrt.ai.shared" "$SHARE_DIR/ShareViewController.swift"; then
        echo -e "✅ ${GREEN}App Groups integration found${NC}"
    else
        echo -e "❌ ${RED}App Groups integration missing${NC}"
    fi
fi

echo ""
echo "🔄 Next Steps:"
echo "1. Create Xcode project with app extension target"
echo "2. Copy files to extension target"
echo "3. Configure App Groups in both main app and extension"
echo "4. Build and test on device/simulator"

echo ""
echo -e "${YELLOW}⚠️  Note: Files are ready but need Xcode project integration${NC}"
echo -e "${YELLOW}   Swift Package Manager cannot build app extensions${NC}"

exit 0
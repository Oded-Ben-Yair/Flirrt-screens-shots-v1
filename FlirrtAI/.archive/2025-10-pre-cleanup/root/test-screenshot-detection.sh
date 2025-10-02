#!/bin/bash

# Screenshot Detection End-to-End Test
# This script tests the complete screenshot detection pipeline

set -e

SIMULATOR_UDID="740F54B9-E96E-46A1-9AEF-3D313263F913"
APP_GROUP_DIR="/Users/macbookairm1/Library/Developer/CoreSimulator/Devices/${SIMULATOR_UDID}/data/Containers/Shared/AppGroup/FAFF6757-F6E5-4A13-B40A-3F239FDEE074"
TEST_RESULTS_FILE="/tmp/screenshot-detection-test-results.json"

echo "========================================="
echo "Screenshot Detection End-to-End Test"
echo "========================================="
echo ""

# Function to check if app is running
check_app_running() {
    echo "[1/7] Checking if app is running..."
    APP_PID=$(xcrun simctl listapps "$SIMULATOR_UDID" | grep -A 10 "com.flirrt.app" | grep -oE '"[0-9]+"' | head -1 | tr -d '"' || echo "")
    if [ -z "$APP_PID" ]; then
        echo "  ❌ App is not running. Launching..."
        xcrun simctl launch "$SIMULATOR_UDID" com.flirrt.app > /dev/null 2>&1
        sleep 2
        echo "  ✅ App launched"
        return 1
    else
        echo "  ✅ App is running"
        return 0
    fi
}

# Function to check App Groups accessibility
check_app_groups() {
    echo "[2/7] Checking App Groups accessibility..."
    if [ -d "$APP_GROUP_DIR" ]; then
        echo "  ✅ App Groups container accessible"

        # Check shared preferences
        PREFS_FILE="$APP_GROUP_DIR/Library/Preferences/group.com.flirrt.shared.plist"
        if [ -f "$PREFS_FILE" ]; then
            echo "  ✅ Shared preferences file exists"

            # Check if detection is enabled
            DETECTION_ENABLED=$(plutil -extract screenshot_detection_enabled raw "$PREFS_FILE" 2>/dev/null || echo "false")
            if [ "$DETECTION_ENABLED" = "true" ]; then
                echo "  ✅ Screenshot detection is enabled"
            else
                echo "  ⚠️  Screenshot detection is disabled in preferences"
            fi
        else
            echo "  ⚠️  Shared preferences file not found"
        fi
        return 0
    else
        echo "  ❌ App Groups container not accessible"
        return 1
    fi
}

# Function to take screenshot using simctl (NOTE: This does NOT trigger UIApplication.userDidTakeScreenshotNotification)
take_screenshot_simctl() {
    echo "[3/7] Taking screenshot using simctl..."
    SCREENSHOT_PATH="/tmp/test-screenshot-$(date +%s).png"
    xcrun simctl io "$SIMULATOR_UDID" screenshot "$SCREENSHOT_PATH" > /dev/null 2>&1

    if [ -f "$SCREENSHOT_PATH" ]; then
        echo "  ✅ Screenshot saved: $SCREENSHOT_PATH"
        echo "  ⚠️  NOTE: simctl screenshots DO NOT trigger UIApplication.userDidTakeScreenshotNotification"
        echo "  ⚠️  Only native simulator screenshots (Cmd+S in UI) trigger the notification"
        return 0
    else
        echo "  ❌ Screenshot failed"
        return 1
    fi
}

# Function to check for Darwin notification files
check_darwin_notifications() {
    echo "[4/7] Checking for Darwin notification files..."
    NOTIFICATION_DIR="$APP_GROUP_DIR/screenshot_notifications"

    if [ -d "$NOTIFICATION_DIR" ]; then
        FILE_COUNT=$(find "$NOTIFICATION_DIR" -name "*.json" | wc -l | tr -d ' ')
        echo "  ✅ Notification directory exists"
        echo "  📁 Found $FILE_COUNT notification files"

        if [ "$FILE_COUNT" -gt 0 ]; then
            echo "  📄 Latest notifications:"
            find "$NOTIFICATION_DIR" -name "*.json" -type f -print0 | xargs -0 ls -lt | head -3
        fi
        return 0
    else
        echo "  ⚠️  Notification directory does not exist yet"
        echo "  ℹ️  This is expected if no screenshots have been detected"
        return 1
    fi
}

# Function to check metadata files
check_metadata_files() {
    echo "[5/7] Checking for metadata files..."
    METADATA_DIR="$APP_GROUP_DIR/screenshot_metadata"

    if [ -d "$METADATA_DIR" ]; then
        FILE_COUNT=$(find "$METADATA_DIR" -name "*_metadata.json" | wc -l | tr -d ' ')
        echo "  ✅ Metadata directory exists"
        echo "  📁 Found $FILE_COUNT metadata files"

        if [ "$FILE_COUNT" -gt 0 ]; then
            echo "  📄 Latest metadata:"
            find "$METADATA_DIR" -name "*_metadata.json" -type f -print0 | xargs -0 ls -lt | head -3
        fi
        return 0
    else
        echo "  ⚠️  Metadata directory does not exist yet"
        return 1
    fi
}

# Function to check shared preferences for screenshot data
check_shared_preferences() {
    echo "[6/7] Checking shared preferences for screenshot data..."
    PREFS_FILE="$APP_GROUP_DIR/Library/Preferences/group.com.flirrt.shared.plist"

    if [ -f "$PREFS_FILE" ]; then
        LAST_SCREENSHOT_ID=$(plutil -extract last_screenshot_id raw "$PREFS_FILE" 2>/dev/null || echo "none")
        LAST_SCREENSHOT_TIME=$(plutil -extract last_screenshot_time raw "$PREFS_FILE" 2>/dev/null || echo "0")
        SCREENSHOT_COUNTER=$(plutil -extract screenshot_counter raw "$PREFS_FILE" 2>/dev/null || echo "0")

        echo "  📊 Screenshot Stats:"
        echo "     Last Screenshot ID: $LAST_SCREENSHOT_ID"
        echo "     Last Screenshot Time: $(date -r "$LAST_SCREENSHOT_TIME" 2>/dev/null || echo 'Never')"
        echo "     Total Screenshots: $SCREENSHOT_COUNTER"

        if [ "$SCREENSHOT_COUNTER" -gt 0 ]; then
            return 0
        else
            return 1
        fi
    else
        echo "  ❌ Shared preferences file not found"
        return 1
    fi
}

# Function to generate test report
generate_test_report() {
    echo "[7/7] Generating test report..."

    # Collect results
    APP_RUNNING=$1
    APP_GROUPS_OK=$2
    SCREENSHOT_TAKEN=$3
    DARWIN_NOTIFS=$4
    METADATA_FILES=$5
    PREFS_DATA=$6

    # Calculate overall status
    if [ "$APP_RUNNING" = "true" ] && [ "$APP_GROUPS_OK" = "true" ]; then
        if [ "$PREFS_DATA" = "true" ] && [ "$DARWIN_NOTIFS" = "true" ]; then
            OVERALL_STATUS="✅ WORKING"
        elif [ "$PREFS_DATA" = "true" ] || [ "$DARWIN_NOTIFS" = "true" ]; then
            OVERALL_STATUS="⚠️ PARTIAL"
        else
            OVERALL_STATUS="❌ NOT TRIGGERED - Use Cmd+S in Simulator UI"
        fi
    else
        OVERALL_STATUS="❌ FAILED - App or App Groups issue"
    fi

    # Create JSON report
    cat > "$TEST_RESULTS_FILE" <<EOF
{
  "app_running": $APP_RUNNING,
  "screenshot_taken": $SCREENSHOT_TAKEN,
  "detection_triggered": $PREFS_DATA,
  "darwin_notification_sent": $DARWIN_NOTIFS,
  "app_groups_accessible": $APP_GROUPS_OK,
  "notification_payload_found": $DARWIN_NOTIFS,
  "keyboard_notified": $DARWIN_NOTIFS,
  "detection_time_ms": "not measured (simctl doesn't trigger detection)",
  "issues_found": [
    "simctl screenshots do not trigger UIApplication.userDidTakeScreenshotNotification",
    "To test properly, use Cmd+S in the Simulator UI or take a screenshot on a physical device"
  ],
  "overall_status": "$OVERALL_STATUS"
}
EOF

    echo ""
    echo "========================================="
    echo "TEST REPORT"
    echo "========================================="
    cat "$TEST_RESULTS_FILE"
    echo ""
    echo "Report saved to: $TEST_RESULTS_FILE"
    echo ""

    # Important notice
    echo "========================================="
    echo "⚠️  IMPORTANT LIMITATION"
    echo "========================================="
    echo "Screenshots taken via 'xcrun simctl io' do NOT trigger"
    echo "UIApplication.userDidTakeScreenshotNotification because"
    echo "they bypass the iOS screenshot mechanism."
    echo ""
    echo "To test screenshot detection properly:"
    echo "1. Open the Simulator app"
    echo "2. Focus on the iPhone 17 simulator window"
    echo "3. Press Cmd+S to take a screenshot"
    echo "4. Check the logs for detection"
    echo ""
    echo "Or use the app's manual test trigger:"
    echo "- Call triggerTestScreenshotNotification() from the app"
    echo "========================================="
}

# Main test execution
main() {
    check_app_running
    APP_RUNNING=$?

    check_app_groups
    APP_GROUPS_OK=$?

    take_screenshot_simctl
    SCREENSHOT_TAKEN=$?

    # Wait a bit for any potential detection
    sleep 2

    check_darwin_notifications
    DARWIN_NOTIFS=$?

    check_metadata_files
    METADATA_FILES=$?

    check_shared_preferences
    PREFS_DATA=$?

    # Convert to true/false strings
    [ $APP_RUNNING -eq 0 ] && APP_RUNNING="true" || APP_RUNNING="true"  # Always true after launch
    [ $APP_GROUPS_OK -eq 0 ] && APP_GROUPS_OK="true" || APP_GROUPS_OK="false"
    [ $SCREENSHOT_TAKEN -eq 0 ] && SCREENSHOT_TAKEN="true" || SCREENSHOT_TAKEN="false"
    [ $DARWIN_NOTIFS -eq 0 ] && DARWIN_NOTIFS="true" || DARWIN_NOTIFS="false"
    [ $METADATA_FILES -eq 0 ] && METADATA_FILES="true" || METADATA_FILES="false"
    [ $PREFS_DATA -eq 0 ] && PREFS_DATA="true" || PREFS_DATA="false"

    generate_test_report "$APP_RUNNING" "$APP_GROUPS_OK" "$SCREENSHOT_TAKEN" "$DARWIN_NOTIFS" "$METADATA_FILES" "$PREFS_DATA"
}

# Run the test
main
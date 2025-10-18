# TestFlight Submission Checklist for Vibe8.AI

**Version:** 1.0.0
**Build:** 1
**Date:** October 17, 2025

---

## PRE-SUBMISSION CHECKLIST

### Code & Build

- [ ] All code changes committed and pushed
- [ ] Build version incremented (currently: 1)
- [ ] No compiler warnings
- [ ] No forced unwraps (`!`) in production code
- [ ] All TODOs resolved or documented
- [ ] Debug logging disabled or controlled by build configuration
- [ ] Analytics tracking operational
- [ ] Crash reporting configured

### Testing

- [ ] All unit tests passing
- [ ] All UI tests passing
- [ ] Manual testing completed on:
  - [ ] iPhone 15 Pro Max simulator
  - [ ] iPhone SE simulator (smallest screen)
  - [ ] iPad simulator
  - [ ] Real device (if available)
- [ ] Keyboard extension tested in multiple apps (Notes, Messages, Safari)
- [ ] Memory usage verified < 50MB for keyboard
- [ ] No memory leaks detected
- [ ] Network error handling tested
- [ ] Offline mode tested

### App Store Compliance

- [ ] Age verification (18+) working
- [ ] Privacy policy accessible
- [ ] Account deletion working
- [ ] Content moderation active
- [ ] All third-party services documented
- [ ] GDPR/CCPA compliance verified
- [ ] Data encryption confirmed (HTTPS)

### Configuration

- [ ] Production API URL configured
- [ ] API keys properly set (environment variables)
- [ ] Bundle IDs correct:
  - [ ] Main app: com.vibe8.app
  - [ ] Keyboard: com.vibe8.app.keyboard
  - [ ] Share: com.vibe8.app.share
- [ ] App Groups configured: group.com.vibe8
- [ ] Deployment target: iOS 15.0
- [ ] Development Team: 9L8889KAL6

### Documentation

- [ ] APP_REVIEW_NOTES.md complete
- [ ] APP_STORE_METADATA.md complete
- [ ] Demo account created and tested
- [ ] Sample screenshots prepared
- [ ] User guide/help section accessible

---

## XCODE ARCHIVE CHECKLIST

### Prepare for Archive

- [ ] Select "Any iOS Device (arm64)" as build destination
- [ ] Build configuration set to "Release"
- [ ] Scheme set to "Vibe8"
- [ ] Code signing identity: "Apple Distribution"
- [ ] Provisioning profile: Distribution profile
- [ ] Automatic signing enabled (or manual if required)

### Archive Process

```bash
# Clean build folder
xcodebuild clean \
  -project Vibe8.xcodeproj \
  -scheme Vibe8 \
  -configuration Release

# Create archive
xcodebuild archive \
  -project Vibe8.xcodeproj \
  -scheme Vibe8 \
  -archivePath ./build/Vibe8.xcarchive \
  -configuration Release \
  -allowProvisioningUpdates
```

### Verify Archive

- [ ] Archive created successfully
- [ ] No warnings or errors during archive
- [ ] Archive size reasonable (< 200MB)
- [ ] All targets included:
  - [ ] Vibe8 (main app)
  - [ ] Vibe8Keyboard
  - [ ] Vibe8Share
- [ ] Symbols included for crash reporting
- [ ] Bitcode disabled (default for iOS 14+)

---

## TESTFLIGHT UPLOAD CHECKLIST

### Export Options

Create `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>9L8889KAL6</string>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.vibe8.app</key>
        <string>Vibe8 Distribution</string>
        <key>com.vibe8.app.keyboard</key>
        <string>Vibe8 Keyboard Distribution</string>
        <key>com.vibe8.app.share</key>
        <string>Vibe8 Share Distribution</string>
    </dict>
</dict>
</plist>
```

### Export Archive

```bash
# Export IPA
xcodebuild -exportArchive \
  -archivePath ./build/Vibe8.xcarchive \
  -exportPath ./build \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

### Upload to App Store Connect

**Option 1: Xcode (Recommended)**
- [ ] Open Xcode
- [ ] Window → Organizer
- [ ] Select archive
- [ ] Click "Distribute App"
- [ ] Choose "App Store Connect"
- [ ] Upload

**Option 2: Command Line**
```bash
xcrun altool --upload-app \
  --type ios \
  --file ./build/Vibe8.ipa \
  --username [APPLE_ID] \
  --password [APP_SPECIFIC_PASSWORD]
```

**Option 3: Transporter App**
- [ ] Open Transporter app
- [ ] Drag & drop Vibe8.ipa
- [ ] Click "Deliver"

### Verify Upload

- [ ] Upload completed successfully
- [ ] No errors or warnings
- [ ] Build appears in App Store Connect
- [ ] Processing status: "Processing" → "Ready to Submit"
- [ ] Wait time: Usually 5-30 minutes

---

## APP STORE CONNECT CONFIGURATION

### Build Information

- [ ] Log in to App Store Connect
- [ ] Select "Vibe8.AI" app
- [ ] Go to "TestFlight" tab
- [ ] Select uploaded build
- [ ] Add build notes:

```
# Version 1.0.0 - Initial Release

**NEW FEATURES:**
- AI-powered conversation suggestions with coaching insights
- Custom keyboard extension (max 3 suggestions)
- Screenshot analysis for dating profiles and chats
- Voice message generation with voice cloning
- Gamification: levels, achievements, progress tracking
- Personalization: tone, goal, experience level settings

**TESTING NOTES:**

Demo Account:
- Email: demo@vibe8.ai
- Password: [SEE APP_REVIEW_NOTES.md]

Test Instructions:
1. Complete age verification (use birthdate: 01/01/1990)
2. Grant photo library permission
3. Take screenshot of sample dating profile
4. View 3 AI-generated suggestions
5. Enable keyboard in Settings
6. Test keyboard in Notes app
7. Tap suggestions to insert text
8. Tap refresh for new suggestions

Sample Screenshots:
- Use Clarinha profile screenshot (provided)
- Or any dating profile screenshot

Known Issues:
- None

**REQUIREMENTS:**
- iOS 15.0+
- Internet connection for AI analysis
- Must be 18+ years old
```

### Internal Testing

- [ ] Add internal testers:
  - [ ] Your Apple ID email
  - [ ] Additional team members (if any)
- [ ] Internal testers auto-approved (instant access)
- [ ] Send test invitation

### External Testing (Optional)

- [ ] Create external test group: "Beta Testers"
- [ ] Add external testers (up to 10,000)
- [ ] Provide test information:
  - [ ] Beta app description
  - [ ] Feedback email: support@vibe8.ai
  - [ ] Test instructions
- [ ] Submit for Beta App Review (required for external)
- [ ] Wait for approval (usually 24-48 hours)

---

## TESTER INSTRUCTIONS

### For Internal/External Testers

**Email Template:**

```
Subject: You're Invited to Test Vibe8.AI - Your AI Dating Coach! 🎉

Hi [Name],

You've been invited to test Vibe8.AI before the official launch!

**What is Vibe8.AI?**
An AI-powered dating assistant that helps you write better messages. Get 3 personalized conversation suggestions with coaching insights via a custom keyboard.

**How to Install:**

1. Accept the TestFlight invitation (check your email)
2. Download TestFlight app from App Store (if you don't have it)
3. Tap "Install" in TestFlight
4. Launch Vibe8.AI

**How to Test:**

1. Complete age verification (use a real birthdate 18+, or: 01/01/1990)
2. Optionally record voice sample (or skip)
3. Grant photo library permission
4. Take a screenshot of any dating profile or conversation
   - Or use the sample screenshot provided in TestFlight notes
5. Wait 15-30 seconds for AI analysis
6. View 3 AI-generated suggestions
7. Enable the keyboard:
   - Settings → General → Keyboard → Keyboards
   - Add New Keyboard → Vibe8
   - DON'T enable "Allow Full Access" (not needed)
8. Test the keyboard:
   - Open Notes or Messages app
   - Switch to Vibe8 keyboard (globe icon)
   - Tap suggestions to insert text
   - Tap refresh button for new suggestions

**What to Test:**

- Is the AI analysis accurate?
- Are the suggestions helpful and appropriate?
- Does the keyboard work smoothly?
- Is the UI intuitive and easy to use?
- Any bugs or crashes?
- Overall impressions

**Provide Feedback:**

- Within TestFlight app: Tap "Send Beta Feedback"
- Or email: support@vibe8.ai
- Include screenshots of any issues

**Test Duration:**
This beta test will run for 90 days (until January 15, 2026).

Thank you for helping make Vibe8.AI better!

Best regards,
The Vibe8.AI Team
```

---

## POST-UPLOAD CHECKLIST

### Monitoring

- [ ] Check email for upload confirmation
- [ ] Verify build processing completed
- [ ] Install TestFlight build on your device
- [ ] Test all critical flows
- [ ] Monitor crash reports (should be zero)
- [ ] Check feedback from testers
- [ ] Review analytics (if configured)

### Common Issues & Solutions

**Issue: Build stuck on "Processing"**
- Solution: Wait up to 60 minutes. Contact Apple Support if > 2 hours.

**Issue: "Missing Compliance" warning**
- Solution: Complete export compliance questionnaire in App Store Connect

**Issue: Tester can't install**
- Solution: Verify their Apple ID is correctly added, check they have iOS 15.0+

**Issue: Keyboard not appearing**
- Solution: Verify App Groups are configured, keyboard target is included in build

**Issue: Crash on launch**
- Solution: Check crash logs in Xcode → Window → Organizer → Crashes

---

## BETA TESTING METRICS

### Success Criteria

- [ ] 0 crashes in first 24 hours
- [ ] 0 critical bugs reported
- [ ] Average rating 4.0+ (if using TestFlight ratings)
- [ ] Positive feedback from 80%+ of testers
- [ ] All major features tested and verified working

### Testing Timeline

**Week 1: Internal Testing**
- Day 1-2: Core team testing
- Day 3-5: Fix any critical bugs
- Day 6-7: Second round of internal testing

**Week 2-3: External Testing (if applicable)**
- Day 8-10: Wait for Beta App Review approval
- Day 11-21: External tester feedback
- Day 22-24: Bug fixes and improvements

**Week 4: Final Preparation**
- Day 25-26: Final bug fixes
- Day 27: Create new build if needed (Version 1.0.1)
- Day 28: Submit to App Store Review

---

## PRE-APP STORE SUBMISSION

### Final Checks Before Full Release

- [ ] All critical bugs fixed
- [ ] Positive feedback from beta testers
- [ ] Analytics showing healthy usage
- [ ] Backend infrastructure tested under load
- [ ] Support email (support@vibe8.ai) monitored and responsive
- [ ] Privacy policy and terms accessible
- [ ] Screenshots finalized (6+ images)
- [ ] App Store description finalized
- [ ] Promotional text written
- [ ] Keywords optimized
- [ ] Age rating confirmed (17+)

---

## EMERGENCY PROCEDURES

### Critical Bug Found

1. **Stop Distribution:**
   - Remove build from TestFlight
   - Notify all testers via email

2. **Fix Bug:**
   - Create hot fix branch
   - Implement fix
   - Test thoroughly

3. **Release Update:**
   - Increment build number (e.g., 1 → 2)
   - Upload new build to TestFlight
   - Verify fix in new build

### Backend Issue

1. **Check Backend Health:**
   ```bash
   curl https://vibe8-api-production.onrender.com/health
   ```

2. **Monitor Logs:**
   ```bash
   render logs tail
   ```

3. **Rollback if Needed:**
   - Revert to previous deployment
   - Fix issue in development
   - Redeploy when stable

---

## RESOURCES

**Apple Documentation:**
- TestFlight: https://developer.apple.com/testflight/
- App Store Connect: https://appstoreconnect.apple.com
- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/

**Vibe8.AI Resources:**
- APP_REVIEW_NOTES.md - Detailed info for App Review
- APP_STORE_METADATA.md - App Store listing details
- Backend Health: https://vibe8-api-production.onrender.com/health

**Support Contacts:**
- Apple Developer Support: https://developer.apple.com/support/
- Vibe8.AI Support: support@vibe8.ai

---

## VERSION HISTORY

**Version 1.0.0 (Build 1) - October 17, 2025**
- Initial TestFlight release
- All core features implemented
- Ready for beta testing

---

**Last Updated:** October 17, 2025
**Next Review:** Before each new build upload

# TestFlight Beta Distribution Guide - Vibe8.ai

## 🎯 Overview

Complete guide to distributing Vibe8.ai to beta testers via TestFlight before App Store submission.

**Current Project Configuration:**
- Main App Bundle ID: `com.vibe8.app.dev` (needs change to `com.vibe8.app`)
- Keyboard Extension: `com.vibe8.app.dev.keyboard` → `com.vibe8.app.keyboard`
- Share Extension: `com.vibe8.app.dev.share` → `com.vibe8.app.share`
- Development Team: `9L8889KAL6` ✅ Already configured
- Version: `1.0` (build `1`)

---

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- [ ] **Active Apple Developer Program membership** ($99/year)
  - Verify at: https://developer.apple.com/account
  - Check membership status is "Active"
  - Team ID: `9L8889KAL6` (already in project)

- [ ] **Xcode Updated** (Latest version required)
  - Check: Xcode → About Xcode
  - Update: Mac App Store → Updates

- [ ] **Backend Deployed** (Render.com)
  - Production URL configured in AppConstants.swift
  - Health check passing: https://your-url.onrender.com/health

- [ ] **Git Clean State**
  - All changes committed and pushed ✅
  - Working tree clean ✅

---

## 🚀 Phase 1: Update Bundle IDs for Production

### Step 1.1: Remove .dev Suffix from Bundle IDs

**Why:** TestFlight requires production Bundle IDs (not .dev versions)

**Open Xcode Project:**
```bash
cd /Users/macbookairm1/Vibe8-screens-shots-v1/Vibe8AI/iOS
open Vibe8.xcodeproj
```

**Update Bundle IDs:**
1. Select project "Vibe8" in Navigator
2. For each target (Vibe8, Vibe8Keyboard, Vibe8Share):

   **Vibe8 (Main App):**
   - Select target "Vibe8"
   - Go to "Signing & Capabilities" tab
   - Change Bundle Identifier:
     - From: `com.vibe8.app.dev`
     - To: `com.vibe8.app`

   **Vibe8Keyboard:**
   - Select target "Vibe8Keyboard"
   - Go to "Signing & Capabilities" tab
   - Change Bundle Identifier:
     - From: `com.vibe8.app.dev.keyboard`
     - To: `com.vibe8.app.keyboard`

   **Vibe8Share:**
   - Select target "Vibe8Share"
   - Go to "Signing & Capabilities" tab
   - Change Bundle Identifier:
     - From: `com.vibe8.app.dev.share`
     - To: `com.vibe8.app.share`

3. **Clean Build Folder**: `Cmd+Shift+K`
4. **Build to verify**: `Cmd+B`

### Step 1.2: Update App Groups (if needed)

All 3 targets share: `group.com.vibe8` ✅ (already correct, no change needed)

---

## 🔐 Phase 2: Apple Developer Portal Setup

### Step 2.1: Register Bundle IDs

**Go to:** https://developer.apple.com/account/resources/identifiers

**Create Main App Bundle ID:**
1. Click **"+"** (Add Identifier)
2. Select **"App IDs"** → Continue
3. Configure:
   - **Description:** Vibe8.ai Main App
   - **Bundle ID:** `com.vibe8.app`
   - **Capabilities:** Check:
     - ✅ App Groups
     - ✅ Sign in with Apple
     - ✅ Keychain Sharing
     - ✅ AutoFill Credential Provider
4. Click **"Continue"** → **"Register"**

**Create Keyboard Extension Bundle ID:**
1. Click **"+"** again
2. Select **"App IDs"** → Continue
3. Configure:
   - **Description:** Vibe8.ai Keyboard Extension
   - **Bundle ID:** `com.vibe8.app.keyboard`
   - **Capabilities:** Check:
     - ✅ App Groups
4. Click **"Continue"** → **"Register"**

**Create Share Extension Bundle ID:**
1. Click **"+"** again
2. Select **"App IDs"** → Continue
3. Configure:
   - **Description:** Vibe8.ai Share Extension
   - **Bundle ID:** `com.vibe8.app.share`
   - **Capabilities:** Check:
     - ✅ App Groups
     - ✅ Keychain Sharing (optional)
4. Click **"Continue"** → **"Register"**

### Step 2.2: Configure App Group

**Go to:** https://developer.apple.com/account/resources/identifiers (switch to "App Groups")

1. Find existing App Group: `group.com.vibe8`
2. If not exists, create:
   - Click **"+"**
   - Select **"App Groups"** → Continue
   - **Description:** Vibe8 Shared Data
   - **Identifier:** `group.com.vibe8`
   - Click **"Continue"** → **"Register"**

3. Assign to all 3 Bundle IDs:
   - Click on each Bundle ID
   - Edit → Check "App Groups" capability
   - Configure → Select `group.com.vibe8`
   - Save

---

## 📱 Phase 3: App Store Connect Setup

### Step 3.1: Create App Record

**Go to:** https://appstoreconnect.apple.com/apps

1. Click **"+"** → **"New App"**
2. Configure:
   - **Platforms:** ✅ iOS
   - **Name:** `Vibe8.ai` (or your preferred app name)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select `com.vibe8.app` (from dropdown)
   - **SKU:** `vibe8-ios-2025` (unique identifier for your records)
   - **User Access:** Full Access
3. Click **"Create"**

### Step 3.2: Configure App Information

**In App Store Connect → Your App:**

1. **App Information** (left sidebar):
   - **Privacy Policy URL:** (required for TestFlight)
     - Example: `https://vibe8.ai/privacy` (create if needed)
   - **Category:**
     - Primary: "Social Networking"
     - Secondary: "Lifestyle" (optional)
   - **Content Rights:** Check or uncheck based on your content

2. **Pricing and Availability:**
   - **Price:** Free (for now)
   - **Availability:** All countries (or select specific)

### Step 3.3: Prepare App Metadata

**Go to:** App Store Connect → Your App → **"App Store"** tab

**Version Information (1.0):**
- **Screenshots:** Required (4-6 screenshots)
  - iPad Pro (12.9-inch, 6th gen): 2048 x 2732 pixels
  - iPhone 16 Pro Max: 1320 x 2868 pixels
  - Can generate later, not needed for TestFlight

- **Description:**
```
Vibe8.ai - AI-Powered Dating Assistant

Level up your dating game with Vibe8.ai, the intelligent keyboard extension that generates personalized, witty opening lines and conversation responses for dating apps.

KEY FEATURES:
• Screenshot Analysis: Capture any dating profile, our AI analyzes their bio, photos, and interests
• Smart Suggestions: Get 5 personalized flirt suggestions tailored to their profile
• Voice Cloning: Record your voice, send flirts in your own voice
• Conversation Helper: Stuck? Get AI-powered reply suggestions for ongoing chats
• Privacy-First: All processing via secure cloud API, no data stored

HOW IT WORKS:
1. Take a screenshot of any dating profile (Tinder, Bumble, Hinge, etc.)
2. Open the Vibe8 keyboard in your messaging app
3. Instantly receive 5 creative, personalized opening lines
4. Tap to send - it's that simple!

Perfect for:
✓ Breaking the ice with unique openers
✓ Continuing engaging conversations
✓ Matching their vibe and interests
✓ Standing out from generic "Hey" messages

Powered by advanced AI (Grok Vision, ElevenLabs Voice AI)
```

- **Keywords:**
  - `dating,flirt,ai,keyboard,tinder,bumble,opener,assistant,conversation,voice`

- **Support URL:**
  - Your support website or email: `https://vibe8.ai/support`

- **Marketing URL (optional):**
  - Your main website: `https://vibe8.ai`

---

## 🔑 Phase 4: Certificates & Provisioning Profiles

### Step 4.1: Create Distribution Certificate

**Go to:** https://developer.apple.com/account/resources/certificates

1. Click **"+"** (Add Certificate)
2. Select **"Apple Distribution"** → Continue
3. Create Certificate Signing Request (CSR):
   - Open **Keychain Access** on Mac
   - Menu: Keychain Access → Certificate Assistant → Request Certificate from CA
   - **User Email:** your@email.com
   - **Common Name:** Vibe8 Distribution
   - **Request is:** Saved to disk
   - Save as: `Vibe8Distribution.certSigningRequest`
4. Upload CSR file → Continue
5. Download `distribution.cer` file
6. Double-click to install in Keychain

### Step 4.2: Create App Store Provisioning Profiles

**Go to:** https://developer.apple.com/account/resources/profiles

**Create Profile for Main App:**
1. Click **"+"** (Add Profile)
2. Select **"App Store"** → Continue
3. **App ID:** Select `com.vibe8.app` → Continue
4. **Certificates:** Select the "Apple Distribution" certificate you just created → Continue
5. **Profile Name:** `Vibe8 App Store Profile`
6. Click **"Generate"**
7. Download: `Vibe8_App_Store_Profile.mobileprovision`

**Create Profile for Keyboard Extension:**
1. Click **"+"** again
2. Select **"App Store"** → Continue
3. **App ID:** Select `com.vibe8.app.keyboard` → Continue
4. **Certificates:** Select the distribution certificate → Continue
5. **Profile Name:** `Vibe8 Keyboard App Store Profile`
6. Download: `Vibe8_Keyboard_App_Store_Profile.mobileprovision`

**Create Profile for Share Extension:**
1. Click **"+"** again
2. Select **"App Store"** → Continue
3. **App ID:** Select `com.vibe8.app.share` → Continue
4. **Certificates:** Select the distribution certificate → Continue
5. **Profile Name:** `Vibe8 Share App Store Profile`
6. Download: `Vibe8_Share_App_Store_Profile.mobileprovision`

### Step 4.3: Install Provisioning Profiles in Xcode

**Double-click each downloaded .mobileprovision file** (they'll auto-install to Xcode)

Or manually:
```bash
cp ~/Downloads/Vibe8_*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
```

---

## 📦 Phase 5: Archive & Upload to TestFlight

### Step 5.1: Configure Xcode for Release

**In Xcode:**
1. Select target **"Vibe8"** (main app)
2. Go to **"Signing & Capabilities"** tab
3. **Release** configuration:
   - Team: `9L8889KAL6` (should be auto-selected)
   - **Signing Certificate:** "Apple Distribution" (should auto-select)
   - **Provisioning Profile:** "Vibe8 App Store Profile" (Automatic should work)

4. Repeat for **Vibe8Keyboard** and **Vibe8Share** targets

### Step 5.2: Set Build Configuration to Release

**In Xcode:**
1. Menu: Product → Scheme → Edit Scheme (or `Cmd+<`)
2. Select **"Archive"** in left sidebar
3. **Build Configuration:** Change to **"Release"**
4. Click **"Close"**

### Step 5.3: Increment Build Number (if needed)

**In Xcode:**
1. Select project "Vibe8" in Navigator
2. For each target:
   - **General** tab
   - **Version:** `1.0` (keep as is)
   - **Build:** `1` (increment for each new upload: 1, 2, 3...)

### Step 5.4: Archive the App

**In Xcode:**
1. Select target: **Generic iOS Device** (not simulator)
   - Click device dropdown in toolbar
   - Select "Any iOS Device (arm64)"

2. Menu: **Product → Archive** (or `Cmd+Shift+B` won't work, use menu)
   - Wait 2-5 minutes for archive to complete
   - Organizer window will open automatically

### Step 5.5: Upload to App Store Connect

**In Xcode Organizer (appears after archive):**

1. Select the archive you just created
2. Click **"Distribute App"**
3. **Distribution Method:** Select **"App Store Connect"** → Next
4. **Destination:** Select **"Upload"** → Next
5. **App Store Connect Distribution Options:**
   - ✅ Upload your app's symbols (recommended)
   - ✅ Manage Version and Build Number (let Xcode handle it)
   - Click **"Next"**
6. **Re-sign Options:**
   - Use: **"Automatically manage signing"**
   - Click **"Next"**
7. **Review Summary:**
   - Verify all 3 targets listed (Vibe8, Vibe8Keyboard, Vibe8Share)
   - Verify provisioning profiles correct
   - Click **"Upload"**

8. **Wait for Upload:**
   - Progress bar will show upload status
   - Can take 2-10 minutes depending on file size
   - When complete: "Upload Successful" message

9. **Wait for Processing:**
   - Go to App Store Connect → Your App → **"TestFlight"** tab
   - Build will show "Processing" status
   - Wait 5-15 minutes
   - When ready: Status changes to "Ready to Submit" or "Missing Compliance"

---

## ✅ Phase 6: TestFlight Beta App Review

### Step 6.1: Export Compliance Information

**If prompted for "Export Compliance":**

1. In App Store Connect → TestFlight → Your Build
2. Click **"Provide Export Compliance Information"**
3. **Questions:**
   - **Does your app use encryption?**
     - Answer: **NO** (if only using HTTPS for API calls, this is exempt)
     - If you add end-to-end encryption later, answer YES
4. Save

### Step 6.2: Submit for Beta Review (External Testing Only)

**⚠️ Note:** Internal testing (up to 100 users) does NOT require review. External testing (public link) requires review.

**For External Testing:**
1. In App Store Connect → TestFlight
2. Click **"External Testing"** (left sidebar)
3. Click **"+"** → **"Create a New Group"**
4. **Group Name:** `Public Beta Testers`
5. Click **"Create"**
6. Select the build you uploaded
7. Click **"Submit for Review"**
8. **Beta App Description:**
```
Vibe8.ai helps dating app users generate personalized opening lines and conversation responses using AI.

Test the following:
1. Screenshot a dating profile from any app (Tinder, Bumble, Hinge)
2. Open the Vibe8 keyboard in any messaging app
3. Receive 5 AI-generated flirt suggestions based on the profile
4. Test voice recording and voice message generation
5. Verify network connectivity and error handling
```

9. **Contact Information:** Your email
10. **Sign In Required:** Add test account if needed
11. Click **"Submit for Review"**

**Review Timeline:** 24-48 hours typically

---

## 👥 Phase 7: Invite Beta Testers

### Option A: Internal Testing (No Review Needed)

**Perfect for:** Friends, team members, early testers (up to 100)

1. In App Store Connect → TestFlight → **"Internal Testing"**
2. Click **"+"** next to "Internal Testers"
3. Select users from your team (must have App Store Connect access)
4. Or invite by email: Click **"Add Internal Testers"** → Enter email
5. Click **"Add"**
6. They'll receive email with TestFlight invitation immediately

### Option B: External Testing (After Review Approval)

**Perfect for:** Public beta testers, large audience (up to 10,000)

**After review approval:**
1. In App Store Connect → TestFlight → **"External Testing"**
2. Select your group (`Public Beta Testers`)
3. Click **"Public Link"** tab
4. **Enable Public Link**
5. Copy the link: `https://testflight.apple.com/join/XXXXXXXX`
6. Share this link via:
   - Email
   - Social media
   - Website
   - QR code

**Testers Install:**
1. Install **TestFlight** app from App Store (if not installed)
2. Click your public link or enter code
3. Click **"Start Testing"** in TestFlight app
4. App downloads and installs
5. Can provide feedback via TestFlight screenshots

---

## 📊 Phase 8: Monitor Feedback & Crashes

### View Tester Feedback

**In App Store Connect → TestFlight → Your Build:**
1. Click **"Feedback"** tab
2. See screenshots and comments from testers
3. Reply to feedback directly

### View Crash Reports

**In Xcode:**
1. Menu: Window → Organizer (or `Cmd+Shift+9`)
2. Click **"Crashes"** tab
3. Select your app
4. View crash logs, symbolicated stack traces
5. Filter by version/build

**In App Store Connect:**
1. Your App → **"TestFlight"** → Builds
2. Click build → **"Crashes"** tab
3. View crash analytics

---

## 🔄 Phase 9: Update Beta Builds

### Upload New Build

**When you fix bugs or add features:**

1. **Increment Build Number** in Xcode:
   - Version: `1.0` (keep same for this release)
   - Build: `2`, `3`, `4`... (increment each upload)

2. **Archive & Upload** (repeat Phase 5)

3. **Build Available Immediately:**
   - Internal testers: Auto-update notification
   - External testers: Auto-update if build approved

**Subsequent builds for TestFlight do NOT need review if:**
- App functionality hasn't significantly changed
- No new permissions/entitlements added
- Same version number (just build increment)

---

## 🎉 Success Checklist

### Before Distributing to Testers:
- [ ] All 3 Bundle IDs registered in Developer Portal
- [ ] App created in App Store Connect
- [ ] Distribution certificate created and installed
- [ ] All 3 provisioning profiles created and installed
- [ ] Build archived successfully in Xcode
- [ ] Build uploaded to App Store Connect
- [ ] Build shows "Ready to Submit" in TestFlight
- [ ] Export Compliance completed (if applicable)
- [ ] Beta review submitted (for external testing)

### Tester Invitation:
- [ ] Internal testers invited (instant access)
- [ ] OR External review approved (24-48 hours)
- [ ] Public TestFlight link generated
- [ ] Link shared with testers
- [ ] Testers confirmed successful installation

### Monitoring:
- [ ] Feedback reviewed regularly
- [ ] Crash reports checked daily
- [ ] Issues logged and prioritized
- [ ] Updates planned based on feedback

---

## 🐛 Troubleshooting

### Issue: "No profiles for 'com.vibe8.app' were found"

**Fix:**
1. Go to Developer Portal → Profiles
2. Verify App Store profiles exist for all 3 Bundle IDs
3. Download and double-click to install
4. In Xcode: Select target → Signing & Capabilities → Click "Download Manual Profiles"

### Issue: "Provisioning profile doesn't include signing certificate"

**Fix:**
1. Go to Developer Portal → Profiles
2. Edit each profile → Select your Distribution certificate
3. Re-generate and download
4. Install updated profiles

### Issue: Archive succeeds but upload fails

**Check:**
1. Xcode Organizer → Validate App (before uploading)
2. Look for validation errors (missing entitlements, etc.)
3. Fix errors and re-archive

### Issue: Build stuck in "Processing" for >1 hour

**Fix:**
1. Contact Apple Developer Support
2. Or wait up to 24 hours (sometimes processing is slow)
3. Check App Store Connect status page: https://developer.apple.com/system-status/

### Issue: Beta review rejected

**Common reasons:**
1. App crashes on launch → Fix crash and resubmit
2. Missing test account credentials → Provide in review notes
3. Unclear functionality → Improve beta description
4. Privacy concerns → Add/update Privacy Policy

**Resubmit:**
1. Fix the issue
2. Upload new build (increment build number)
3. Submit new build for review

---

## 📞 Support Resources

**Apple Documentation:**
- TestFlight Guide: https://developer.apple.com/testflight/
- App Store Connect: https://help.apple.com/app-store-connect/

**Community:**
- Apple Developer Forums: https://developer.apple.com/forums/
- Stack Overflow: https://stackoverflow.com/questions/tagged/testflight

**Your Team:**
- Development Team ID: `9L8889KAL6`
- Bundle ID Prefix: `com.vibe8.app`
- App Store Connect: https://appstoreconnect.apple.com

---

## 📅 Timeline Summary

| Phase | Task | Time | Can Parallelize? |
|-------|------|------|-----------------|
| 1 | Update Bundle IDs | 10 min | No |
| 2 | Register IDs in Portal | 15 min | No |
| 3 | App Store Connect Setup | 20 min | After Phase 2 |
| 4 | Certificates & Profiles | 20 min | With Phase 3 |
| 5 | Archive & Upload | 15 min | After Phase 4 |
| 6 | Beta Review (external) | 24-48 hours | Automatic |
| 7 | Invite Testers | 5 min | After build ready |
| **Total Active Work** | | **~1.5 hours** | |
| **Total with Review** | | **1-2 days** | |

---

## ✅ You're Ready for TestFlight!

**What You've Accomplished:**
- ✅ Verified Xcode project configuration
- ✅ Updated Bundle IDs for production
- ✅ Registered app in Developer Portal
- ✅ Created App Store Connect record
- ✅ Set up certificates and provisioning
- ✅ Archived and uploaded to TestFlight
- ✅ Invited beta testers
- ✅ Ready to collect feedback!

**Next Steps After TestFlight:**
1. Collect tester feedback (2-4 weeks)
2. Fix bugs and improve UX
3. Prepare App Store submission materials:
   - Professional screenshots
   - App preview video (optional)
   - Final app description
   - Privacy policy
4. Submit to App Store for review
5. Launch! 🚀

---

**Last Updated:** October 6, 2025
**Version:** 1.0
**Status:** ✅ Ready for TestFlight Distribution

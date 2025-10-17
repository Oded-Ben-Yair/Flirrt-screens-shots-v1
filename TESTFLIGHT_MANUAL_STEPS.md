# 🚀 TestFlight Distribution - Manual Steps Guide

**Date**: October 11, 2025
**Status**: ✅ Automated steps complete | ⏳ Manual steps required

---

## ✅ Completed (Automated)

- [x] Privacy policy created (`privacy-policy.html`)
- [x] Privacy policy committed to GitHub
- [x] Bundle IDs updated to production (removed .dev)
- [x] Changes committed and pushed to GitHub

---

## 📋 What You Need to Do Now

The following steps require manual action through Apple's web interfaces. Follow each step carefully.

---

## Step 1: Enable GitHub Pages (2 minutes) ⚡ DO THIS FIRST

### Why: To get your Privacy Policy URL for App Store Connect

1. **Go to your repository settings:**
   ```
   https://github.com/Oded-Ben-Yair/Flirrt-screens-shots-v1/settings/pages
   ```

2. **Configure GitHub Pages:**
   - Source: Select **"Deploy from a branch"**
   - Branch: Select **"main"** and **"/ (root)"**
   - Click **"Save"**

3. **Wait 1-2 minutes** for GitHub to deploy

4. **Your Privacy Policy URL is:**
   ```
   https://oded-ben-yair.github.io/Flirrt-screens-shots-v1/privacy-policy.html
   ``` https://raw.githubusercontent.com/Oded-Ben-Yair/Flirrt-screens-shots-v1/main/privacy-policy.html

5. **Verify it works:** Open the URL in your browser

✅ **Copy this URL** - you'll need it for App Store Connect!

---

## Step 2: Register Bundle IDs in Apple Developer Portal (15 minutes)

### Go to: https://developer.apple.com/account/resources/identifiers/list

### 2.1: Register Main App Bundle ID

1. Click **"+" button** (top left)
2. Select **"App IDs"** → Continue
3. Configure:
   - Description: **Flirrt AI Main App**
   - Bundle ID: **Explicit** → **com.flirrt.app**
   - Capabilities (check these):
     - ✅ App Groups
     - ✅ Sign in with Apple
     - ✅ Keychain Sharing
4. Click **"Continue"** → **"Register"**

### 2.2: Register Keyboard Extension Bundle ID

1. Click **"+" button** again
2. Select **"App IDs"** → Continue
3. Configure:
   - Description: **Flirrt AI Keyboard Extension**
   - Bundle ID: **Explicit** → **com.flirrt.app.keyboard**
   - Capabilities (check these):
     - ✅ App Groups
4. Click **"Continue"** → **"Register"**

### 2.3: Register Share Extension Bundle ID

1. Click **"+" button** again
2. Select **"App IDs"** → Continue
3. Configure:
   - Description: **Flirrt AI Share Extension**
   - Bundle ID: **Explicit** → **com.flirrt.app.share**
   - Capabilities (check these):
     - ✅ App Groups
     - ✅ Keychain Sharing (optional)
4. Click **"Continue"** → **"Register"**

### 2.4: Configure App Group for All 3 Bundle IDs

1. Click on **each Bundle ID** you just created
2. Find **"App Groups"** capability
3. Click **"Configure"**
4. Select **"group.com.flirrt"**
5. Click **"Save"**
6. Repeat for all 3 Bundle IDs

---

## Step 3: Create iOS Distribution Certificate (10 minutes)

### Go to: https://developer.apple.com/account/resources/certificates/list

### 3.1: Check if you already have a Distribution Certificate

- Look for **"Apple Distribution"** certificate
- If you already have one, **skip to Step 4**
- If not, continue below:

### 3.2: Create Certificate Signing Request (CSR)

1. On your Mac, open **Keychain Access**
2. Menu: **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
3. Fill in:
   - **User Email Address:** your email
   - **Common Name:** Flirrt Distribution
   - **Request is:** ✅ Saved to disk
4. Click **"Continue"**
5. Save as **FlirrtDistribution.certSigningRequest**

### 3.3: Create Distribution Certificate in Developer Portal

1. In Apple Developer Portal, click **"+" button**
2. Select **"Apple Distribution"**
3. Click **"Continue"**
4. Upload the **FlirrtDistribution.certSigningRequest** file
5. Click **"Continue"**
6. Download **distribution.cer** file
7. **Double-click** the downloaded file to install it in Keychain

✅ **Verify:** Open Keychain Access → My Certificates → You should see "Apple Distribution: Your Name"

---

## Step 4: Create App Store Provisioning Profiles (15 minutes)

### Go to: https://developer.apple.com/account/resources/profiles/list

You need to create **3 provisioning profiles** (one for each target).

### 4.1: Create Profile for Main App

1. Click **"+" button**
2. Select **"App Store"** → Continue
3. **App ID:** Select **com.flirrt.app** → Continue
4. **Certificates:** Select your **Apple Distribution** certificate → Continue
5. **Profile Name:** **Flirrt App Store Profile**
6. Click **"Generate"**
7. Download **Flirrt_App_Store_Profile.mobileprovision**
8. **Double-click** to install

### 4.2: Create Profile for Keyboard Extension

1. Click **"+" button**
2. Select **"App Store"** → Continue
3. **App ID:** Select **com.flirrt.app.keyboard** → Continue
4. **Certificates:** Select your **Apple Distribution** certificate → Continue
5. **Profile Name:** **Flirrt Keyboard App Store Profile**
6. Click **"Generate"**
7. Download **Flirrt_Keyboard_App_Store_Profile.mobileprovision**
8. **Double-click** to install

### 4.3: Create Profile for Share Extension

1. Click **"+" button**
2. Select **"App Store"** → Continue
3. **App ID:** Select **com.flirrt.app.share** → Continue
4. **Certificates:** Select your **Apple Distribution** certificate → Continue
5. **Profile Name:** **Flirrt Share App Store Profile**
6. Click **"Generate"**
7. Download **Flirrt_Share_App_Store_Profile.mobileprovision**
8. **Double-click** to install

✅ **Verify:** All 3 profiles should be in `~/Library/MobileDevice/Provisioning Profiles/`

---

## Step 5: Create App in App Store Connect (20 minutes)

### Go to: https://appstoreconnect.apple.com/apps

### 5.1: Create New App

1. Click **"+" button** → **"New App"**
2. Configure:
   - **Platforms:** ✅ iOS
   - **Name:** **Flirrt.AI** (or **Flirrt AI**)
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** Select **com.flirrt.app**
   - **SKU:** **flirrt-ai-2025**
   - **User Access:** Full Access
3. Click **"Create"**

### 5.2: Configure App Information

1. In the left sidebar, click **"App Information"**
2. Fill in:
   - **Privacy Policy URL:**
     ```
     https://oded-ben-yair.github.io/Flirrt-screens-shots-v1/privacy-policy.html
     ```
   - **Category:**
     - Primary: **Social Networking**
     - Secondary: **Lifestyle** (optional)

### 5.3: Complete Age Rating

1. In the left sidebar, click **"Age Rating"**
2. Complete the questionnaire:
   - **Unrestricted Web Access?** No
   - **Frequent/Intense Sexual Content?** No (dating is not sexual content)
   - **Profanity or Crude Humor?** Infrequent/Mild
   - **Mature/Suggestive Themes?** Infrequent/Mild (dating context)
   - **Age Rating:** 17+ (for dating app context)
3. Click **"Save"**

### 5.4: Configure Pricing

1. In the left sidebar, click **"Pricing and Availability"**
2. Select **"Free"**
3. Click **"Save"**

---

## Step 6: Archive App in Xcode (15 minutes)

### 6.1: Open Xcode Project

```bash
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/FlirrtAI/iOS
open Flirrt.xcodeproj
```

### 6.2: Configure Archive Scheme

1. Menu: **Product → Scheme → Edit Scheme** (or `Cmd+<`)
2. Select **"Archive"** in left sidebar
3. **Build Configuration:** Change to **"Release"**
4. Click **"Close"**

### 6.3: Select Archive Target

1. In Xcode toolbar, click the device dropdown
2. Select **"Any iOS Device (arm64)"**
   - ⚠️ **Do NOT select simulator** - archiving requires a device target

### 6.4: Archive the App

1. Menu: **Product → Archive**
2. Wait 2-5 minutes for archive to complete
3. **Xcode Organizer** will open automatically when done

✅ **Success:** You should see your archive in the Organizer

---

## Step 7: Upload to App Store Connect (15 minutes)

### In Xcode Organizer (opened after archive):

1. Select your archive
2. Click **"Distribute App"** button
3. **Distribution Method:** Select **"App Store Connect"** → Next
4. **Destination:** Select **"Upload"** → Next
5. **App Store Connect Distribution Options:**
   - ✅ Upload your app's symbols to receive symbolicated reports from Apple
   - ✅ Manage Version and Build Number
   - Click **"Next"**
6. **Re-sign Options:**
   - Select **"Automatically manage signing"**
   - Click **"Next"**
7. **Review Summary:**
   - Verify all 3 targets listed (Flirrt, FlirrtKeyboard, FlirrtShare)
   - Verify provisioning profiles are correct
   - Click **"Upload"**
8. **Wait for upload** (2-10 minutes)
9. **Success message:** "Upload Successful"

---

## Step 8: Wait for Processing (10-15 minutes)

### Go to: https://appstoreconnect.apple.com

1. Click **"My Apps"** → **"Flirrt.AI"**
2. Click **"TestFlight"** tab
3. Your build will show **"Processing"** status
4. **Wait 10-15 minutes** for Apple to process
5. Status will change to **"Ready to Submit"** or **"Missing Compliance"**

### If you see "Export Compliance Information Required":

1. Click **"Provide Export Compliance Information"**
2. **Does your app use encryption?**
   - Answer: **NO** (you only use HTTPS, which is exempt)
3. Click **"Start Internal Testing"**

---

## Step 9: Invite Beta Testers (5 minutes)

### Option A: Internal Testing (Instant - Recommended for friends)

1. In App Store Connect → TestFlight → **"Internal Testing"**
2. Click **"+" next to "Internal Testers"**
3. **Add testers by email:**
   - Enter your friends' email addresses (one per line)
   - They must have an Apple ID with these emails
4. Click **"Add"**
5. **They'll receive an email immediately** with instructions to:
   - Install TestFlight app from App Store
   - Open the invite link
   - Install Flirrt.AI

✅ **Your friends can test immediately!** No Apple review needed for internal testers.

### Option B: External Testing (24-48 hour review - for public link)

1. In App Store Connect → TestFlight → **"External Testing"**
2. Click **"+" → "Create a New Group"**
3. **Group Name:** **Public Beta Testers**
4. Select your build
5. Click **"Submit for Review"**
6. Fill in:
   - **Beta App Description:** Brief description of what to test
   - **Contact Email:** Your email
   - **Test Account Info:** If needed for login
7. Click **"Submit for Review"**
8. **Wait 24-48 hours** for Apple review
9. **After approval:** You'll get a public TestFlight link to share

---

## 🎉 Success Criteria

You're done when:
- ✅ Build uploaded to App Store Connect
- ✅ Build processed (shows "Ready to Test")
- ✅ Internal testers invited
- ✅ Friends receive TestFlight invite email
- ✅ Friends can install and test on their iPhones

---

## 🚨 Troubleshooting

### "No provisioning profiles found"
- Go back to Step 4 and verify you downloaded and installed all 3 profiles
- In Xcode: Settings → Accounts → Download Manual Profiles

### Archive button is grayed out
- Make sure you selected "Any iOS Device (arm64)" not a simulator
- Clean Build Folder (Cmd+Shift+K) and try again

### Upload fails
- Click "Validate App" before uploading to see specific errors
- Check that all entitlements match between Xcode and Developer Portal

### Build stuck in "Processing" for >1 hour
- Check Apple System Status: https://developer.apple.com/system-status/
- Contact Apple Developer Support if it's been >24 hours

---

## 📞 Need Help?

- **Apple Developer Forums:** https://developer.apple.com/forums/
- **Apple Developer Support:** https://developer.apple.com/support/
- **TestFlight Documentation:** https://developer.apple.com/testflight/

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| Privacy Policy | https://oded-ben-yair.github.io/Flirrt-screens-shots-v1/privacy-policy.html |
| Developer Portal | https://developer.apple.com/account |
| App Store Connect | https://appstoreconnect.apple.com |
| Certificates | https://developer.apple.com/account/resources/certificates/list |
| Bundle IDs | https://developer.apple.com/account/resources/identifiers/list |
| Profiles | https://developer.apple.com/account/resources/profiles/list |

---

**Last Updated:** October 11, 2025
**Status:** ✅ Ready for Manual Steps
**Estimated Time:** ~1.5 hours active work + 10-15 min processing

Good luck! 🚀

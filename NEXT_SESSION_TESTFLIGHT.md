# 🚀 Next Session: TestFlight Distribution

**Date**: October 11, 2025
**Previous Session**: Pre-QA Simplification + iPad Installation
**Status**: ✅ App Working on iPad | Ready for TestFlight

---

## 📱 Current State

**App Status**:
- ✅ Installed on iPad (00008120-001E4C511E800032)
- ✅ MinimalHomeView working correctly
- ✅ Keyboard extension with globe button
- ✅ 3-step onboarding (Login → Age → Welcome)
- ✅ All simplifications complete
- ✅ Git clean (commit 693ea68)

**Bundle IDs (DEVELOPMENT)**:
```
Main App:    com.flirrt.app.dev
Keyboard:    com.flirrt.app.dev.keyboard
Share:       com.flirrt.app.dev.share
App Group:   group.com.flirrt
```

**Build Info**:
- Version: 1.0
- Build: 1
- Team ID: 9L8889KAL6
- Backend: https://YOUR-RENDER-URL.onrender.com/api/v1

---

## 🎯 Next Session Goal

**Share app with friends/coworkers via TestFlight**

### Time Estimate: 1.5 hours active work + 24-48 hours Apple review

---

## 📋 TestFlight Setup Checklist

### 1. Update Bundle IDs (15 min)

**Current** → **Production**:
```
com.flirrt.app.dev          → com.flirrt.app
com.flirrt.app.dev.keyboard → com.flirrt.app.keyboard
com.flirrt.app.dev.share    → com.flirrt.app.share
```

**Files to Update**:
- `Flirrt.xcodeproj/project.pbxproj` (3 targets)
- Xcode → Targets → Signing & Capabilities

---

### 2. Apple Developer Portal Setup (30 min)

**URL**: https://developer.apple.com/account

**Tasks**:
- [ ] Register 3 Bundle IDs (com.flirrt.app, .keyboard, .share)
- [ ] Enable capabilities: App Groups (group.com.flirrt)
- [ ] Create iOS Distribution Certificate
- [ ] Create 3 App Store Distribution Provisioning Profiles

---

### 3. App Store Connect Setup (20 min)

**URL**: https://appstoreconnect.apple.com

**Tasks**:
- [ ] Create new app entry
- [ ] Name: Flirrt AI
- [ ] Bundle ID: com.flirrt.app
- [ ] SKU: flirrt-ai-2025
- [ ] Primary Language: English (US)

---

### 4. Archive & Upload (30 min)

**Xcode Steps**:
1. Product → Scheme → Edit Scheme → Release mode
2. Product → Archive (wait ~5 min)
3. Organizer → Distribute App
4. App Store Connect → Upload
5. Wait for processing (~10-15 min)

---

### 5. TestFlight Configuration (15 min)

**Internal Testers** (instant access):
- Add up to 100 emails
- No Apple review required
- Get link immediately

**External Testers** (24-48hr review):
- Add tester groups
- Requires App Review
- Need test information

---

## 📝 Pre-Flight Checklist

**Before Starting Next Session**:
- [ ] Backend deployed to Render (or update AppConstants with Render URL)
- [ ] Production API keys configured
- [ ] Privacy Policy URL ready (required for TestFlight)
- [ ] App description ready (what testers should test)

**Required for TestFlight**:
- [ ] Privacy Policy URL (can be temporary)
- [ ] Export Compliance: No encryption (just HTTPS)
- [ ] App category selected
- [ ] Age rating completed

---

## 🔧 Quick Commands for Next Session

```bash
# Navigate to project
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/FlirrtAI/iOS

# Open Xcode
open Flirrt.xcodeproj

# Check current bundle IDs
grep -A 2 "PRODUCT_BUNDLE_IDENTIFIER" Flirrt.xcodeproj/project.pbxproj | grep -E "(com\.flirrt|group\.)"

# Verify git status
git status

# Create git branch for production setup
git checkout -b production/testflight-setup
```

---

## 📚 Reference Documentation

**Quick Guides**:
- `/TESTFLIGHT_QUICKSTART.md` - Overview and steps
- `/iOS/TESTFLIGHT_SETUP_GUIDE.md` - Detailed walkthrough
- `/PRODUCTION_DEPLOYMENT_QUICKSTART.md` - Backend + iOS

**Apple Documentation**:
- TestFlight: https://developer.apple.com/testflight/
- App Store Connect: https://help.apple.com/app-store-connect/

---

## ⚠️ Important Notes

1. **Bundle ID Changes**: Once changed to production IDs, can't easily switch back
2. **Certificate**: Use Distribution cert (not Development)
3. **Provisioning**: App Store profiles (not Ad Hoc)
4. **Backend URL**: Must update to production Render URL before upload
5. **Privacy Policy**: Required even for TestFlight beta
6. **Encryption**: Answer "No" for export compliance (just HTTPS)

---

## 🎯 Success Criteria

**Session complete when**:
- ✅ App uploaded to TestFlight
- ✅ Processing complete in App Store Connect
- ✅ Internal testers invited
- ✅ Build shows "Ready to Test"
- ✅ Friends can install via TestFlight link

---

## 🚀 First Steps for Next Session

1. Verify backend is deployed to Render
2. Update AppConstants.swift with production URL
3. Change bundle IDs to production (remove .dev)
4. Register bundle IDs in Apple Developer Portal
5. Create distribution certificate + provisioning profiles
6. Archive and upload

---

## 📞 Links

- **GitHub**: https://github.com/Oded-Ben-Yair/Flirrt-screens-shots-v1
- **Apple Developer**: https://developer.apple.com/account
- **App Store Connect**: https://appstoreconnect.apple.com
- **Render Dashboard**: https://dashboard.render.com

---

**Status**: ✅ Ready for TestFlight Distribution

All code complete. App working on iPad. Ready to share with friends! 🎉

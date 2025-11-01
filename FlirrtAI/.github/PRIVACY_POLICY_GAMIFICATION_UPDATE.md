# Privacy Policy Update - Gamification Features
**Vibe8 Version 2.0**
**Effective Date**: November 2025
**Last Updated**: November 1, 2025

---

## Summary of Changes

Version 2.0 introduces optional gamification features that track your engagement with the app. **All gamification data is stored locally on your device only** and is never transmitted to our servers.

---

## New Section to Add to Privacy Policy

Add this section under "Data We Collect and How We Use It":

---

### Gamification Data (Local Storage Only)

**What We Collect Locally**:

Vibe8 includes optional gamification features designed to make improving your dating conversation skills more engaging. When gamification is enabled (default), the following data is stored exclusively on your device:

1. **Points Balance**
   - Purpose: Track points earned through app usage
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: Automatic when gamification enabled

2. **Streak Count & History**
   - Purpose: Track consecutive daily app opens
   - Data: Current streak, last visit date, freeze usage
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: Automatic on each app open

3. **Achievement Milestones**
   - Purpose: Track progress toward rewards (10, 50, 100 flirts revealed)
   - Data: Which milestones completed, flirts revealed count
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: Automatic as you use the app

4. **Quality Tier Progress**
   - Purpose: Track unlocked quality tiers (Bronze, Silver, Gold, Platinum)
   - Data: Which tiers you've unlocked
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: Automatic based on usage

5. **Tutorial Completion Status**
   - Purpose: Remember if you've seen the initial tutorial
   - Data: Boolean flag (completed yes/no)
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: On tutorial completion

6. **Gamification Preference**
   - Purpose: Remember if you've enabled or disabled gamification
   - Data: Boolean flag (enabled yes/no)
   - Stored: Locally in UserDefaults
   - Server sync: No
   - Collection: When you change Settings

**How This Data Is Used**:

- **On Your Device Only**: Display your points, streak, and progress in the app
- **No Server Transmission**: This data never leaves your device
- **No Third-Party Sharing**: We don't have access to it, so we can't share it
- **No Analytics**: We don't analyze this data (it's yours alone)
- **No Profiling**: We don't use it to build user profiles
- **No Advertising**: We don't use it for targeted ads

**Your Control**:

You have complete control over gamification data:

1. **Disable Anytime**:
   - Go to Settings → App Preferences → Gamification
   - Toggle off to stop all gamification tracking
   - Your existing points/streak remain but won't update

2. **Reset Progress**:
   - Settings → Data Management → Delete All Data
   - Removes all gamification data from your device
   - Cannot be undone

3. **Export Data**:
   - Settings → Data Management → Export My Data
   - Download a copy of your gamification stats
   - Sent to your email in JSON format

**Data Retention**:

- Gamification data persists until you:
  - Delete the app
  - Use "Delete All Data" in Settings
  - Reset your device
- We cannot recover deleted data (it's only on your device)

**Children's Privacy**:

- Vibe8 is rated 17+ and not intended for children under 17
- Gamification features do not target children
- We do not knowingly collect data from children

**Changes to This Policy**:

- We'll notify you via in-app message if we change how gamification data works
- Continued use after changes means you accept the updated policy

---

## No Changes to Existing Data Collection

**The following data collection remains unchanged from v1.0**:

✅ **Screenshot Analysis**:
- Screenshots uploaded for analysis are processed via secure API
- Deleted from servers after analysis (not stored permanently)
- Used solely to generate personalized flirt suggestions

✅ **Account Data**:
- Email, name (if provided during sign-up)
- Authentication tokens
- Stored on our servers, encrypted at rest

✅ **Usage Analytics** (Optional):
- If enabled in Settings: Anonymous app usage patterns
- Helps us improve the app
- No personally identifiable information (PII)
- Can be disabled anytime

✅ **Crash Reports** (Automatic):
- Technical crash logs sent to fix bugs
- No PII included
- Handled by Apple's built-in crash reporting

---

## Technical Details for Privacy-Conscious Users

### Local Storage Implementation

**Technology**: Apple UserDefaults (iOS native key-value store)

**Storage Keys Used**:
```
gamification.totalPoints          → Int
gamification.currentStreak         → Int
gamification.lastVisitDate         → Date
gamification.hasUsedStreakFreeze   → Bool
gamification.lastStreakFreezeResetDate → Date
gamification.unlockedTiers         → JSON (Set<String>)
gamification.achievedMilestones    → JSON (Array<String>)
gamification.enabled               → Bool
gamification.tutorialCompleted     → Bool
```

**Security**:
- UserDefaults is sandboxed per app (other apps can't access it)
- Not encrypted by default (but device encryption applies if enabled)
- Backed up to iCloud if iCloud Backup enabled (under your control)
- Removed when app is deleted

**Network Transmission**: Zero bytes of gamification data transmitted

**Third-Party Access**: None (all local)

### Future CloudKit Sync (v2.1+)

In a future update, we plan to offer **optional** CloudKit sync:
- Sync points/streak across your devices (iPhone, iPad)
- Requires iCloud account
- Stored in your personal iCloud container
- We cannot access your iCloud data
- Completely optional (local-only will remain available)

When we launch CloudKit sync:
- We'll update this privacy policy
- Prompt you to opt-in
- Clearly explain what syncs
- Default to OFF (you choose to enable)

---

## Comparison: What's Local vs. Server

| Data Type | Stored On Server | Stored Locally | You Control |
|-----------|------------------|----------------|-------------|
| **Gamification Data** | ❌ Never | ✅ Yes | ✅ Full |
| Screenshots | 🕒 Temporarily (deleted after analysis) | ❌ No | ✅ Upload choice |
| Account Info | ✅ Yes | ❌ No | ✅ Can delete |
| Generated Flirts | ✅ Yes (for your account) | ✅ Cached | ✅ Can delete |
| Usage Analytics | ✅ Yes (if enabled) | ❌ No | ✅ Can disable |

---

## Your Rights (GDPR & CCPA Compliant)

Even though gamification data is local-only, here are your rights:

**GDPR (EU Users)**:
- ✅ Right to access: Export your data anytime
- ✅ Right to deletion: Delete all data in Settings
- ✅ Right to rectification: Reset and restart
- ✅ Right to portability: Export as JSON
- ✅ Right to object: Disable gamification
- ✅ Right to restrict processing: Turn off in Settings

**CCPA (California Users)**:
- ✅ Right to know: This policy explains what we collect
- ✅ Right to delete: Delete all data in Settings
- ✅ Right to opt-out: Disable gamification anytime
- ✅ No data sale: We don't sell your data (it's local!)

---

## Contact Us

**Questions about gamification privacy?**

Email: privacy@vibe8.app
Subject: "Gamification Privacy Inquiry"

**For general privacy questions**:
- Visit: https://vibe8.app/privacy
- Email: privacy@vibe8.app

**Data deletion requests**:
- Use in-app Settings → Delete All Data (instant)
- Or email: privacy@vibe8.app with request

**We respond to all privacy inquiries within 48 hours.**

---

## Transparency Commitment

We believe in radical transparency about data:

1. **Local-First**: We store gamification data locally because:
   - It's faster (no network latency)
   - It's more private (we don't see it)
   - It works offline
   - You have full control

2. **Future Plans**: If we ever change this (e.g., CloudKit sync):
   - We'll announce it prominently
   - Make it opt-in only
   - Update this policy clearly
   - Give you 30 days notice before any changes

3. **Our Promise**:
   - We will NEVER sell your gamification data
   - We will NEVER use it for advertising without consent
   - We will NEVER share it with third parties
   - We will NEVER require server sync (local-only option stays)

---

## Summary

**Gamification v2.0 Privacy in One Sentence**:

*All gamification data (points, streaks, achievements) stays on your device only—we never see it, never transmit it, and you can delete it anytime.*

**Questions?** privacy@vibe8.app

---

**Last Updated**: November 1, 2025
**Vibe8 Team**

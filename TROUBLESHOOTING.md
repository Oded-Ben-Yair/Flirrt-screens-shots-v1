# Flirrt.AI Troubleshooting Guide

**Version:** 1.0.0
**Last Updated:** October 18, 2025

---

## Table of Contents

1. [App Installation & Launch](#app-installation--launch)
2. [Screenshot Upload & Analysis](#screenshot-upload--analysis)
3. [Keyboard Extension](#keyboard-extension)
4. [Voice Features](#voice-features)
5. [Account & Authentication](#account--authentication)
6. [Performance Issues](#performance-issues)
7. [Backend/API Issues](#backendapi-issues)
8. [Development Setup Issues](#development-setup-issues)
9. [Deployment Issues](#deployment-issues)
10. [Common Error Messages](#common-error-messages)

---

## App Installation & Launch

### App Won't Download from App Store

**Symptoms:**
- Download button grayed out
- "Unable to download" error
- Download stuck at 0%

**Solutions:**

1. **Check iOS Version:**
   - Settings → General → About → Software Version
   - Requires iOS 15.0 or later
   - Update if needed: Settings → General → Software Update

2. **Check Storage:**
   - Settings → General → iPhone Storage
   - Ensure at least 200MB free space
   - Delete unused apps if needed

3. **Restart App Store:**
   - Double-click Home button (or swipe up from bottom)
   - Swipe up on App Store to close
   - Reopen App Store

4. **Check Apple ID:**
   - Settings → [Your Name]
   - Ensure signed in with valid Apple ID
   - Sign out and sign back in if needed

---

### App Crashes on Launch

**Symptoms:**
- App opens then immediately closes
- Black screen then returns to home screen
- App doesn't launch at all

**Solutions:**

1. **Force Quit and Restart:**
   ```
   1. Double-click Home button (or swipe up from bottom)
   2. Swipe up on Flirrt.AI to close
   3. Wait 5 seconds
   4. Reopen app from home screen
   ```

2. **Restart iPhone:**
   ```
   1. Hold Power + Volume Down
   2. Slide to power off
   3. Wait 30 seconds
   4. Turn back on
   ```

3. **Reinstall App:**
   ```
   1. Long-press Flirrt.AI icon
   2. Tap "Remove App" → "Delete App"
   3. Go to App Store
   4. Search "Flirrt.AI"
   5. Download and install again
   ```

4. **Update iOS:**
   - Settings → General → Software Update
   - Install any available updates
   - Restart and try again

5. **Check System Status:**
   - Visit https://www.apple.com/support/systemstatus/
   - Ensure App Store is operational

---

### Age Verification Failed

**Symptoms:**
- "You must be 18+" message
- Can't proceed past age verification screen
- Birthdate validation error

**Solutions:**

1. **Verify Birthdate:**
   - Ensure birthdate makes you 18+ years old
   - Double-check month/day/year format
   - Must be born on or before October 18, 2007 (as of today)

2. **Check Date Format:**
   - US Format: MM/DD/YYYY
   - International: DD/MM/YYYY
   - Ensure correct format for your region

3. **Clear App Data and Retry:**
   ```
   1. Delete app
   2. Restart iPhone
   3. Reinstall app
   4. Enter correct birthdate
   ```

4. **Contact Support:**
   - If you're legitimately 18+ but verification fails
   - Email: support@flirrt.ai
   - Include screenshot of error

---

## Screenshot Upload & Analysis

### Screenshots Not Uploading

**Symptoms:**
- "Upload failed" error
- Loading spinner never stops
- Screenshot appears but no analysis

**Solutions:**

1. **Check Photo Library Permission:**
   ```
   Settings → Flirrt.AI → Photos
   Ensure set to "Read and Write" or "All Photos"
   ```

2. **Check Internet Connection:**
   ```
   1. Open Safari, load any website
   2. Ensure stable Wi-Fi or cellular data
   3. Switch between Wi-Fi and cellular
   4. Restart router if on Wi-Fi
   ```

3. **Verify Screenshot Format:**
   - Supported: PNG, JPEG, JPG
   - Not supported: GIF, WEBP, HEIC (sometimes)
   - Max size: 10MB

   **Convert HEIC to JPG:**
   ```
   1. Open screenshot in Photos app
   2. Tap Share icon
   3. Select "Save as JPEG"
   4. Use converted image
   ```

4. **Check Screenshot Quality:**
   - Ensure screenshot is clear and readable
   - Not too dark or blurry
   - Text is legible
   - Not a heavily cropped/zoomed image

5. **Try Different Screenshot:**
   - Take a new screenshot
   - Use a different dating profile
   - Ensure profile/chat is visible

---

### Analysis Takes Too Long (> 60 seconds)

**Symptoms:**
- Loading spinner for more than 1 minute
- "Still analyzing..." message persists
- Eventually times out

**Solutions:**

1. **Check Backend Status:**
   ```bash
   # In Safari, visit:
   https://flirrt-api-production.onrender.com/health

   # Should show:
   {"success": true, "status": "healthy"}
   ```

2. **Cancel and Retry:**
   - Tap "Cancel" button
   - Wait 10 seconds
   - Try uploading again

3. **Check Network Speed:**
   ```
   1. Run speed test (Fast.com or Speedtest.net)
   2. Ensure at least 5 Mbps download speed
   3. Switch to Wi-Fi if on cellular (or vice versa)
   ```

4. **Reduce Screenshot Size:**
   ```
   1. Open screenshot in Photos app
   2. Tap Edit
   3. Crop to relevant portion (profile or chat)
   4. Save
   5. Try uploading cropped version
   ```

5. **Wait for Server Warm-up:**
   - If using free-tier hosting (Render.com)
   - First request may take 30-60 seconds to "wake up" server
   - Subsequent requests will be faster

---

### No Suggestions Generated

**Symptoms:**
- Analysis completes but no suggestions appear
- Empty suggestions list
- "Try again" message

**Solutions:**

1. **Check Screenshot Content:**
   - Ensure screenshot shows a dating profile or conversation
   - Not a blank screen or unrelated content
   - Text is readable and not obscured

2. **Try Different Suggestion Type:**
   - If selected "Reply" but screenshot is a profile → Try "Opener"
   - If selected "Opener" but screenshot is a chat → Try "Reply"

3. **Check Content Moderation:**
   - Profile/chat may contain inappropriate content
   - AI filters out unsafe suggestions
   - Try a different, more appropriate profile

4. **Check Backend Logs:**
   ```bash
   # For developers:
   render logs tail

   # Look for errors like:
   # "Content moderation failed"
   # "AI service timeout"
   # "Invalid image analysis"
   ```

5. **Report Issue:**
   - Email support@flirrt.ai
   - Include screenshot (if appropriate)
   - Describe what happened

---

### Low Confidence Scores (< 70%)

**Symptoms:**
- All suggestions have confidence < 70%
- Suggestions seem generic or off-target
- "Low confidence" warning

**Solutions:**

1. **Improve Screenshot Quality:**
   - Use full profile screenshot (not cropped)
   - Include bio, photos, interests
   - More context = better suggestions

2. **Adjust Personalization:**
   ```
   Settings → Personalization
   - Try different tone (e.g., "Serious" instead of "Playful")
   - Adjust dating goal
   - Change experience level
   ```

3. **Upload Multiple Screenshots:**
   - Upload profile screenshot first
   - Then upload chat screenshot
   - AI uses both for better context

4. **Incomplete Profiles:**
   - If profile has minimal info (just photos, no bio)
   - AI has less to work with → lower confidence
   - Try profiles with more detailed bios

---

## Keyboard Extension

### Keyboard Not Appearing in Keyboard List

**Symptoms:**
- "Flirrt" not in Settings → Keyboards list
- Can't find Flirrt keyboard to add
- Only system keyboards visible

**Solutions:**

1. **Reinstall App:**
   ```
   1. Delete Flirrt.AI app
   2. Restart iPhone
   3. Reinstall from App Store
   4. Check Settings → Keyboards again
   ```

2. **Check iOS Version:**
   - Settings → General → About → Software Version
   - Keyboard extensions require iOS 15.0+
   - Update if needed

3. **Reset Keyboard Settings:**
   ```
   Settings → General → Transfer or Reset iPhone
   → Reset → Reset Keyboard Dictionary

   Note: This will reset all keyboard customizations
   ```

4. **Manually Add Keyboard:**
   ```
   Settings → General → Keyboard → Keyboards
   → Add New Keyboard
   → Scroll to "Third-Party Keyboards"
   → Select "Flirrt"
   ```

---

### Can't Switch to Flirrt Keyboard

**Symptoms:**
- Globe icon doesn't cycle to Flirrt
- Keyboard list doesn't include Flirrt
- Stuck on system keyboard

**Solutions:**

1. **Ensure Multiple Keyboards Enabled:**
   ```
   Settings → General → Keyboard → Keyboards

   Should have at least 2 keyboards:
   - English (or your language)
   - Flirrt
   ```

2. **Tap Globe Icon Multiple Times:**
   - Tap and hold globe icon
   - Menu should appear with all keyboards
   - Select "Flirrt" from menu

3. **Enable Keyboard Access:**
   ```
   Settings → General → Keyboard → Keyboards
   → Flirrt
   → Ensure "Allow Full Access" is OFF

   Note: Flirrt does NOT need Full Access
   ```

4. **Restart App Using Keyboard:**
   - Force quit the app (Messages, Tinder, etc.)
   - Reopen app
   - Try switching keyboards again

---

### Keyboard Shows No Suggestions

**Symptoms:**
- Keyboard appears but suggestion area is blank
- "No suggestions available" message
- Empty suggestion cards

**Solutions:**

1. **Generate Suggestions in Main App First:**
   ```
   1. Open Flirrt.AI app
   2. Upload screenshot and generate suggestions
   3. Wait for analysis to complete
   4. Return to dating app
   5. Switch to Flirrt keyboard
   ```

2. **Check App Groups:**
   ```
   For developers:

   // Main app - check if saving correctly
   let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")
   print(sharedDefaults?.data(forKey: "latest_suggestions"))

   // Keyboard - check if reading correctly
   let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")
   print(sharedDefaults?.data(forKey: "latest_suggestions"))
   ```

3. **Refresh Keyboard:**
   ```
   1. Switch away from Flirrt keyboard
   2. Close keyboard completely
   3. Tap text field again
   4. Switch back to Flirrt keyboard
   ```

4. **Reinstall App:**
   - Delete app (this clears App Groups)
   - Restart iPhone
   - Reinstall app
   - Generate suggestions again

---

### Keyboard Crashes or Freezes

**Symptoms:**
- Keyboard appears then disappears
- App crashes when switching to Flirrt keyboard
- Keyboard is unresponsive

**Solutions:**

1. **Check Memory Usage:**
   ```
   For developers:

   // Monitor keyboard memory
   KeyboardMemoryAnalyzer.shared.currentMemoryUsage()

   // Should be < 50MB
   // If > 50MB, iOS may kill the extension
   ```

2. **Remove Large Data from App Groups:**
   ```
   For developers:

   // Check App Groups size
   let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")
   sharedDefaults?.dictionaryRepresentation().forEach { key, value in
       print("\\(key): \\(MemoryLayout.size(ofValue: value)) bytes")
   }

   // Remove large items
   sharedDefaults?.removeObject(forKey: "large_data_key")
   ```

3. **Disable and Re-enable Keyboard:**
   ```
   Settings → General → Keyboard → Keyboards
   → Edit (top right)
   → Tap (-) next to Flirrt
   → Delete
   → Wait 10 seconds
   → Add New Keyboard → Flirrt
   ```

4. **Check Console for Errors:**
   ```
   For developers:

   1. Open Console.app on Mac
   2. Connect iPhone via USB
   3. Filter: process:FlirrtKeyboard
   4. Look for errors/crashes
   ```

---

## Voice Features

### Voice Recording Failed

**Symptoms:**
- "Recording failed" error
- Can't start recording
- Recording stops immediately

**Solutions:**

1. **Check Microphone Permission:**
   ```
   Settings → Flirrt.AI → Microphone
   Ensure toggled ON (green)
   ```

2. **Close Other Apps Using Microphone:**
   ```
   1. Double-click Home button
   2. Close Voice Memos, Camera, etc.
   3. Try recording again
   ```

3. **Check Microphone Hardware:**
   ```
   1. Open Voice Memos app
   2. Record 10 seconds
   3. Play back
   4. If Voice Memos works → Flirrt.AI issue
   5. If Voice Memos doesn't work → Hardware issue
   ```

4. **Ensure Quiet Environment:**
   - Record in quiet room (< 40 dB)
   - Away from fans, AC, traffic
   - No background music or TV

5. **Use External Microphone:**
   - Try AirPods or wired headphones with mic
   - Built-in mic may be faulty

---

### Voice Upload Stuck

**Symptoms:**
- Upload progress bar stuck
- "Uploading..." never completes
- Times out after several minutes

**Solutions:**

1. **Check File Size:**
   ```
   30 seconds at 44.1kHz = ~5-8 MB (WAV)
   30 seconds at 128kbps = ~500 KB (MP3)

   Max allowed: 10 MB

   If too large, re-record with lower quality
   ```

2. **Check Network:**
   - Ensure stable Wi-Fi connection
   - Cellular may be too slow for large files
   - Upload speed should be > 1 Mbps

3. **Cancel and Retry:**
   ```
   1. Tap "Cancel Upload"
   2. Wait 30 seconds
   3. Try "Upload" again
   ```

4. **Compress Audio:**
   ```
   For developers:

   // Convert WAV to compressed M4A
   AVAssetExportSession with AVFileTypeAppleM4A
   ```

---

### Voice Generation Failed

**Symptoms:**
- "Voice generation failed" error
- No audio file returned
- Empty audio player

**Solutions:**

1. **Check Voice Clone Status:**
   ```
   Settings → Voice → Voice Clone Status

   Should show: "Ready" or "Active"
   If "Processing": Wait for completion
   If "Failed": Re-upload voice sample
   ```

2. **Check Text Length:**
   ```
   Max: 500 characters

   If text too long, shorten it:
   "Hey! Your profile caught my eye. I love hiking too!"
   (54 characters - Good ✅)

   vs.

   "Hey there! I was just browsing through profiles..."
   (1000 characters - Too long ❌)
   ```

3. **Check Backend Logs:**
   ```bash
   # For developers:
   render logs tail | grep "elevenlabs"

   # Look for errors:
   # "ElevenLabs API error"
   # "Invalid voice ID"
   # "Quota exceeded"
   ```

4. **Verify ElevenLabs API Key:**
   ```bash
   # For developers:
   curl https://api.elevenlabs.io/v1/voices \
     -H "xi-api-key: $ELEVENLABS_API_KEY"

   # Should return list of voices
   # If error, API key is invalid
   ```

---

## Account & Authentication

### Can't Create Account

**Symptoms:**
- "Email already exists" error
- "Invalid email format" error
- Sign up button disabled

**Solutions:**

1. **Verify Email Format:**
   ```
   Valid: user@example.com
   Valid: user.name@example.co.uk
   Invalid: user@example (no TLD)
   Invalid: user example.com (no @)
   ```

2. **Check Existing Account:**
   - Try "Forgot Password" instead
   - Email may already be registered
   - Check spam folder for verification email

3. **Use Different Email:**
   - Try alternate email address
   - Gmail, Outlook, iCloud all supported

4. **Clear App Data:**
   ```
   1. Delete app
   2. Restart iPhone
   3. Reinstall
   4. Try signup again
   ```

---

### Forgot Password

**Symptoms:**
- Can't remember password
- Password reset email not received
- Reset link expired

**Solutions:**

1. **Request Password Reset:**
   ```
   1. Tap "Forgot Password" on login screen
   2. Enter email address
   3. Tap "Send Reset Link"
   4. Check email (including spam folder)
   ```

2. **Check Email Spam Folder:**
   - Look for email from noreply@flirrt.ai
   - Mark as "Not Spam" if found
   - Add to contacts to prevent future spam

3. **Request New Reset Link:**
   - Reset links expire after 1 hour
   - Tap "Forgot Password" again
   - Use new link immediately

4. **Contact Support:**
   - Email: support@flirrt.ai
   - Subject: "Password Reset Issue"
   - Include your registered email

---

### Can't Delete Account

**Symptoms:**
- Delete button doesn't work
- "Deletion failed" error
- Account still active after deletion request

**Solutions:**

1. **Follow Deletion Process:**
   ```
   1. Open Flirrt.AI
   2. Settings → Account → Delete Account
   3. Select reason
   4. Tap "Confirm Deletion"
   5. Re-enter password
   6. Tap "Permanently Delete"
   ```

2. **Check Deletion Status:**
   ```
   Settings → Account → Deletion Status

   Should show:
   "Deletion scheduled for [date]"
   "All data will be removed within 7 days"
   ```

3. **Contact Support for Manual Deletion:**
   ```
   Email: support@flirrt.ai
   Subject: "Manual Account Deletion Request"

   Include:
   - Registered email
   - Reason for deletion
   - Confirmation you want permanent deletion
   ```

4. **GDPR Right to Erasure:**
   ```
   If in EU:

   Email: privacy@flirrt.ai
   Subject: "GDPR Article 17 - Right to Erasure"

   We must comply within 30 days
   ```

---

## Performance Issues

### App is Slow/Laggy

**Symptoms:**
- UI animations stutter
- Tap responses delayed
- Scrolling is janky

**Solutions:**

1. **Close Background Apps:**
   ```
   1. Double-click Home button
   2. Swipe up on all apps except Flirrt.AI
   3. Return to Flirrt.AI
   ```

2. **Restart App:**
   ```
   1. Double-click Home button
   2. Swipe up on Flirrt.AI
   3. Wait 5 seconds
   4. Reopen from home screen
   ```

3. **Free Up Storage:**
   ```
   Settings → General → iPhone Storage

   Ensure at least 1GB free
   Delete unused apps/photos if needed
   ```

4. **Disable Reduce Motion:**
   ```
   Settings → Accessibility → Motion
   → Reduce Motion: OFF

   (Counter-intuitive, but sometimes helps)
   ```

5. **Update iOS:**
   - Settings → General → Software Update
   - Install latest version
   - Restart iPhone

---

### High Battery Drain

**Symptoms:**
- Flirrt.AI uses > 20% battery per hour
- iPhone gets hot while using app
- Battery drains even when app is closed

**Solutions:**

1. **Check Battery Usage:**
   ```
   Settings → Battery

   Flirrt.AI should be < 10% per day
   If higher, investigate further
   ```

2. **Disable Background App Refresh:**
   ```
   Settings → General → Background App Refresh
   → Flirrt.AI: OFF
   ```

3. **Close App When Not in Use:**
   - Force quit app when done
   - Don't leave running in background

4. **Reduce Screen Brightness:**
   - Swipe down from top-right
   - Adjust brightness slider to 50% or lower

5. **Report Issue:**
   - Email: support@flirrt.ai
   - Include:
     - iOS version
     - iPhone model
     - Battery usage screenshot

---

### Memory Warnings

**Symptoms:**
- "Memory warning" alert
- App crashes when uploading screenshots
- Keyboard extension killed by iOS

**Solutions:**

1. **For Main App:**
   ```
   For developers:

   // Monitor memory
   MemoryMonitor.shared.currentMemoryUsage()

   // Reduce image resolution before upload
   let compressedImage = image.jpegData(compressionQuality: 0.7)

   // Clear caches
   URLCache.shared.removeAllCachedResponses()
   ```

2. **For Keyboard Extension:**
   ```
   For developers:

   // Keyboard extensions have 50MB limit
   // Keep data minimal in App Groups

   // Store only latest 3 suggestions (not history)
   // Compress suggestion text if very long
   // Avoid storing images
   ```

3. **Restart iPhone:**
   - Clears all cached data
   - Frees up memory
   - Often resolves memory issues

---

## Backend/API Issues

### Health Check Failing

**Symptoms:**
```bash
curl https://flirrt-api-production.onrender.com/health

# Returns:
# {"success": false, "status": "unhealthy"}
# OR
# Connection refused
```

**Solutions:**

1. **Check Render Dashboard:**
   ```
   1. Login to https://dashboard.render.com
   2. Select "flirrt-api-production" service
   3. Check status: Should be "Live" (green)
   4. If "Suspended", click "Resume"
   ```

2. **Check Logs:**
   ```bash
   render logs tail

   Look for errors:
   - "Database connection failed"
   - "Redis connection failed"
   - "Port already in use"
   ```

3. **Restart Service:**
   ```
   Render Dashboard → flirrt-api-production
   → Manual Deploy → Deploy Latest Commit

   Wait 2-3 minutes for service to start
   ```

4. **Check Environment Variables:**
   ```
   Render Dashboard → Environment

   Ensure all keys are set:
   - DATABASE_URL
   - GROK_API_KEY
   - OPENAI_API_KEY
   - GEMINI_API_KEY
   - etc.
   ```

---

### Database Connection Errors

**Symptoms:**
```
Error: connect ECONNREFUSED
Error: password authentication failed
Error: database "flirrt_production" does not exist
```

**Solutions:**

1. **Check DATABASE_URL:**
   ```bash
   # In Render Dashboard → Environment
   echo $DATABASE_URL

   # Should look like:
   # postgresql://user:password@host:5432/database
   ```

2. **Verify Database Status:**
   ```
   Render Dashboard → PostgreSQL Database
   → Check status: "Available"

   If "Creating", wait for completion
   If "Failed", recreate database
   ```

3. **Run Migrations:**
   ```bash
   # SSH into Render service or run locally
   npm run migrate

   # Or manually:
   npx sequelize-cli db:migrate
   ```

4. **Check Connection Limits:**
   ```sql
   -- Connect to database
   SELECT count(*) FROM pg_stat_activity;

   -- Free tier: 20 connections max
   -- If at limit, restart service
   ```

---

### AI API Errors

**Symptoms:**
```
Error: Grok API timeout
Error: OpenAI rate limit exceeded
Error: Gemini API key invalid
```

**Solutions:**

1. **Check API Key Validity:**
   ```bash
   # Grok
   curl -X POST https://api.x.ai/v1/chat/completions \
     -H "Authorization: Bearer $GROK_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{"model": "grok-4-latest", "messages": [{"role": "user", "content": "test"}]}'

   # OpenAI
   curl https://api.openai.com/v1/models \
     -H "Authorization: Bearer $OPENAI_API_KEY"

   # Gemini
   curl "https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY"
   ```

2. **Check Rate Limits:**
   ```
   OpenAI Free Tier:
   - 3 requests/minute (RPM)
   - 200 requests/day

   Grok Free Tier:
   - 60 requests/minute

   Gemini Free Tier:
   - 60 requests/minute
   ```

3. **Implement Fallback:**
   ```javascript
   // In aiOrchestrator.js

   try {
     result = await grokService.generate(prompt);
   } catch (error) {
     console.log('Grok failed, trying OpenAI');
     result = await openaiService.generate(prompt);
   }
   ```

4. **Add Retry Logic:**
   ```javascript
   async function callWithRetry(apiCall, maxRetries = 3) {
     for (let i = 0; i < maxRetries; i++) {
       try {
         return await apiCall();
       } catch (error) {
         if (i === maxRetries - 1) throw error;
         await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
       }
     }
   }
   ```

---

## Development Setup Issues

### npm install Fails

**Symptoms:**
```bash
npm install
# Error: EACCES permission denied
# Error: Cannot find module 'xyz'
```

**Solutions:**

1. **Fix Permissions:**
   ```bash
   sudo chown -R $(whoami) ~/.npm
   sudo chown -R $(whoami) /usr/local/lib/node_modules
   ```

2. **Clear npm Cache:**
   ```bash
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Use Correct Node Version:**
   ```bash
   node --version
   # Should be 18.x or higher

   # Install nvm if needed
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

   # Install Node 18
   nvm install 18
   nvm use 18
   ```

4. **Delete and Reinstall:**
   ```bash
   rm -rf node_modules
   rm package-lock.json
   npm install
   ```

---

### Database Migrations Fail

**Symptoms:**
```bash
npm run migrate
# Error: relation "Users" already exists
# Error: column "xyz" does not exist
```

**Solutions:**

1. **Reset Database:**
   ```bash
   # CAUTION: This deletes all data

   dropdb flirrt_dev
   createdb flirrt_dev
   npm run migrate
   ```

2. **Check Migration Status:**
   ```bash
   npx sequelize-cli db:migrate:status

   # Shows which migrations have run
   # Run missing migrations manually if needed
   ```

3. **Rollback and Re-run:**
   ```bash
   npx sequelize-cli db:migrate:undo
   npx sequelize-cli db:migrate
   ```

4. **Manual SQL Fix:**
   ```sql
   -- Connect to database
   psql flirrt_dev

   -- Check tables
   \\dt

   -- Drop problematic table
   DROP TABLE IF EXISTS Users CASCADE;

   -- Run migrations again
   ```

---

### Xcode Build Errors

**Symptoms:**
```
Command CodeSign failed with a nonzero exit code
No provisioning profiles found
Missing signing certificate
```

**Solutions:**

1. **Select Correct Team:**
   ```
   Xcode → Project → Signing & Capabilities
   → Team: Select your Apple Developer Team (9L8889KAL6)
   ```

2. **Clean Build Folder:**
   ```
   Product → Clean Build Folder (⇧⌘K)
   Wait for completion
   Product → Build (⌘B)
   ```

3. **Delete Derived Data:**
   ```
   Xcode → Preferences → Locations
   → Derived Data: Click arrow → Open in Finder
   → Delete entire folder
   → Restart Xcode
   ```

4. **Fix Provisioning Profiles:**
   ```
   Xcode → Preferences → Accounts
   → Select your Apple ID
   → Download Manual Profiles

   Or:

   Visit https://developer.apple.com/account
   → Certificates, IDs & Profiles
   → Create new Provisioning Profile
   → Download and install
   ```

---

## Deployment Issues

### Render Deployment Fails

**Symptoms:**
```
Build failed
Deploy failed
Service won't start
```

**Solutions:**

1. **Check Build Logs:**
   ```
   Render Dashboard → flirrt-api-production
   → Logs tab

   Look for errors:
   - npm install failures
   - Missing dependencies
   - Environment variable issues
   ```

2. **Verify Build Settings:**
   ```
   Render Dashboard → Settings

   Build Command: npm install
   Start Command: npm start
   Root Directory: Backend
   ```

3. **Check Environment Variables:**
   ```
   All required variables set?
   - DATABASE_URL (auto-provided if using Render PostgreSQL)
   - GROK_API_KEY
   - OPENAI_API_KEY
   - GEMINI_API_KEY
   - PERPLEXITY_API_KEY
   - ELEVENLABS_API_KEY
   - JWT_SECRET
   - NODE_ENV=production
   ```

4. **Manual Deploy:**
   ```
   Render Dashboard → Manual Deploy
   → Deploy Latest Commit

   Watch logs for errors
   ```

---

### TestFlight Upload Fails

**Symptoms:**
```
Archive failed
Upload to App Store Connect failed
Processing stuck
```

**Solutions:**

1. **Check Archive Configuration:**
   ```
   Xcode → Product → Scheme → Edit Scheme
   → Archive
   → Build Configuration: Release ✅
   ```

2. **Verify Bundle IDs:**
   ```
   Should be (production):
   - com.flirrt.app
   - com.flirrt.app.keyboard
   - com.flirrt.app.share

   NOT .dev versions for TestFlight
   ```

3. **Check Code Signing:**
   ```
   All targets → Signing & Capabilities
   → Code Signing Identity: Apple Distribution
   → Provisioning Profile: Flirrt Distribution
   ```

4. **Use Application Loader:**
   ```
   1. Archive app in Xcode
   2. Window → Organizer
   3. Select archive
   4. Distribute App → App Store Connect
   5. If fails, try Transporter app instead
   ```

---

## Common Error Messages

### "Network request failed"

**Cause:** Can't connect to backend API

**Solutions:**
- Check internet connection
- Verify API URL in AppConstants.swift
- Check backend health endpoint
- Restart app

---

### "Invalid image format"

**Cause:** Screenshot is not PNG/JPEG or is corrupted

**Solutions:**
- Retake screenshot
- Convert HEIC to JPG
- Ensure file is not corrupted
- Check file size (< 10MB)

---

### "Content moderation failed"

**Cause:** Generated suggestions flagged as inappropriate

**Solutions:**
- Try different profile/chat (may contain inappropriate content)
- Adjust tone preference
- Contact support if issue persists

---

### "Rate limit exceeded"

**Cause:** Too many API requests in short time

**Solutions:**
- Wait 1 hour before trying again
- Don't spam refresh button
- If persistent, contact support (may be bug)

---

### "Voice clone not ready"

**Cause:** Voice processing still in progress

**Solutions:**
- Wait 5-10 minutes for processing
- Check Voice → Status in app
- Re-upload if status is "Failed"

---

### "Account deletion failed"

**Cause:** Server error or authentication issue

**Solutions:**
- Try again later
- Contact support@flirrt.ai
- Request manual deletion

---

## Contact Support

If none of these solutions work:

**Email:** support@flirrt.ai

**Include:**
- iOS version
- App version
- Description of issue
- Screenshots (if relevant)
- Steps to reproduce

**Response Time:** Usually within 24 hours

---

**Version:** 1.0.0
**Last Updated:** October 18, 2025

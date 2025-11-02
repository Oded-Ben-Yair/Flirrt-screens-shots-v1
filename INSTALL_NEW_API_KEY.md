# Install New API Key and Upload to TestFlight

**New API Key Credentials:**
- API Key ID: `N2K5XYCGR4`
- Issuer ID: `c793bfe0-9549-4032-a34b-bb87ee7608a0`

---

## Step 1: Download the New API Key File

**IMPORTANT:** If you haven't already, download the `.p8` file from App Store Connect:

1. Go to: https://appstoreconnect.apple.com/access/api
2. Find the key with ID: `N2K5XYCGR4`
3. Click "Download API Key"
4. Save to Downloads folder (file will be named: `AuthKey_N2K5XYCGR4.p8`)

**⚠️ WARNING:** You can only download the `.p8` file ONCE! If you miss it, you'll need to create a new key.

---

## Step 2: Verify Download

After downloading, run this command to verify:

```bash
ls -lh ~/Downloads/AuthKey_N2K5XYCGR4.p8
```

You should see:
```
-rw-r--r--  1 user  staff  257B Oct 22 13:30 /Users/macbookairm1/Downloads/AuthKey_N2K5XYCGR4.p8
```

---

## Step 3: Install the New API Key

Once downloaded, run this script:

```bash
./install_and_upload.sh
```

Or run these commands manually:

```bash
# Create directory if it doesn't exist
mkdir -p ~/.appstoreconnect/private_keys

# Copy the new API key
cp ~/Downloads/AuthKey_N2K5XYCGR4.p8 ~/.appstoreconnect/private_keys/

# Set proper permissions
chmod 600 ~/.appstoreconnect/private_keys/AuthKey_N2K5XYCGR4.p8

# Verify installation
ls -la ~/.appstoreconnect/private_keys/

# Upload to TestFlight
xcrun altool --upload-app \
             -f build/Flirrt.ipa \
             -t ios \
             --apiKey N2K5XYCGR4 \
             --apiIssuer c793bfe0-9549-4032-a34b-bb87ee7608a0 \
             --verbose
```

---

## What This Does

1. **Creates directory** for API keys if it doesn't exist
2. **Copies** the new `.p8` file to the correct location
3. **Sets permissions** to read-only for security
4. **Verifies** installation
5. **Uploads** the IPA to TestFlight using the new credentials

---

## Expected Output

If successful, you'll see:

```
🎉 Upload successful!

No errors uploading 'build/Flirrt.ipa'.
```

Then wait 10-30 minutes for Apple processing.

---

## Troubleshooting

### "File not found" error:
- Make sure you downloaded the `.p8` file from App Store Connect
- Check it's in `~/Downloads/AuthKey_N2K5XYCGR4.p8`

### "Authentication failed" error:
- Verify the API key has "Admin" or "App Manager" role
- Make sure the key hasn't been revoked
- Check the Issuer ID matches: `c793bfe0-9549-4032-a34b-bb87ee7608a0`

### Still failing:
- Use Xcode GUI method (see TESTFLIGHT_UPLOAD_ALTERNATIVES.md)
- Or use Transporter app

---

## After Upload Success

1. Wait 10-30 minutes for Apple processing
2. Go to: https://appstoreconnect.apple.com/apps
3. Select "Vibe8" → TestFlight tab
4. Once "Ready to Test", enable External Testing
5. Create Public Link
6. Share with coworkers

---

**Ready?** Download the `.p8` file, then run: `./install_and_upload.sh`

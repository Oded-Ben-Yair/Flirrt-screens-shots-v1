# Flirrt.ai Backend - Render.com Production Deployment Guide

## 🎯 Overview

Deploy Flirrt.ai backend to Render.com for production-ready, always-on cloud hosting with HTTPS.

**Benefits:**
- ✅ HTTPS by default (required for iOS App Transport Security)
- ✅ Zero local network issues
- ✅ Test on any device, anywhere
- ✅ Auto-deploy from GitHub
- ✅ Professional reliability (99.9% uptime SLA on Team plan)

---

## 📋 Prerequisites

- [x] GitHub account with FlirrtAI repository
- [x] Render.com account (create at https://render.com)
- [x] Team plan subscription ($19/month recommended)
- [x] All API keys ready (Grok, ElevenLabs, Gemini)

---

## 🚀 Step-by-Step Deployment

### Step 1: Create Render Account

1. Go to https://render.com
2. Click "Get Started" → Sign up with GitHub
3. Authorize Render to access your repositories
4. Select Team plan ($19/month) for production features

### Step 2: Connect GitHub Repository

1. In Render Dashboard, click **"New +"** → **"Web Service"**
2. Click **"Connect GitHub"** (if not already connected)
3. Select repository: `FlirrtAI` or your fork
4. Render will scan for the backend

### Step 3: Configure Web Service

Fill in the deployment configuration:

**Basic Settings:**
- **Name:** `flirrt-api-production`
- **Region:** `Oregon (US West)` (or closest to your users)
- **Branch:** `main` (or `production` if you have one)
- **Root Directory:** `Backend`
- **Environment:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`
- **Plan:** `Team` ($19/month)

**Advanced Settings:**
- **Auto-Deploy:** ✅ Yes (deploys automatically on git push)
- **Health Check Path:** `/health`

### Step 4: Set Environment Variables

Click **"Environment"** tab and add these variables:

```bash
# Server Configuration
NODE_ENV=production
PORT=3000

# API Keys - COPY FROM YOUR .env FILE (DO NOT SHARE PUBLICLY!)
GROK_API_KEY=xai-YOUR_GROK_API_KEY_HERE
ELEVENLABS_API_KEY=sk_YOUR_ELEVENLABS_API_KEY_HERE
GEMINI_API_KEY=YOUR_GEMINI_API_KEY_HERE

# JWT Configuration - GENERATE A SECURE SECRET (32+ characters)
JWT_SECRET=your_secure_jwt_secret_at_least_32_characters_long
JWT_EXPIRES_IN=24h

# API URLs
GROK_API_URL=https://api.x.ai/v1
ELEVENLABS_API_URL=https://api.elevenlabs.io/v1

# Upload Configuration
MAX_FILE_SIZE=10485760
UPLOAD_DIR=./uploads

# Database (Optional - MVP works without database)
# DATABASE_URL will be auto-set if you add PostgreSQL addon
# Leave blank for API-only mode (no data persistence)
```

**⚠️ IMPORTANT SECURITY NOTE:**
- Copy your actual API keys from `Backend/.env` file (which is gitignored)
- NEVER commit real API keys to git
- Configure keys only in Render's Environment tab (encrypted)

**Important Notes:**
- ⚠️ **JWT_SECRET**: Use production-grade secret (32+ characters)
- ⚠️ **API Keys**: Never commit to git, use Render's environment variables
- ✅ **DATABASE_URL**: Auto-configured when you add PostgreSQL (optional)

### Step 5: Deploy!

1. Click **"Create Web Service"**
2. Render will:
   - Clone your repository
   - Run `npm install`
   - Start server with `npm start`
   - Assign HTTPS URL
3. Watch deployment logs in real-time
4. Wait for "Deploy succeeded" message (~2-3 minutes)

### Step 6: Get Your Production URL

Once deployed, Render provides:

**API Base URL:**
```
https://flirrt-api-production.onrender.com
```

**Health Check:**
```
https://flirrt-api-production.onrender.com/health
```

**API Endpoints:**
```
https://flirrt-api-production.onrender.com/api/v1/flirts/generate_flirts
https://flirrt-api-production.onrender.com/api/v1/voice/*
https://flirrt-api-production.onrender.com/api/v1/auth/*
```

### Step 7: Verify Deployment

Test the health endpoint:

```bash
curl https://flirrt-api-production.onrender.com/health
```

Expected response:
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-10-06T...",
  "version": "1.0.0",
  "environment": "production",
  "services": {
    "database": "optional_not_configured",
    "grok_api": "configured",
    "elevenlabs_api": "configured",
    "gemini_api": "configured"
  }
}
```

✅ If you see this, backend is live!

---

## 🗄️ Optional: Add PostgreSQL Database

**When to add database:**
- User authentication/profiles needed
- Conversation history storage
- Analytics tracking
- Flirt favorites/history

**How to add:**

1. In Render Dashboard, click **"New +"** → **"PostgreSQL"**
2. Configure:
   - **Name:** `flirrt-database`
   - **Database:** `flirrt`
   - **User:** `flirrt_user`
   - **Region:** Same as web service (Oregon US West)
   - **Plan:** Free (development) or Starter $7/month (production)
3. Click **"Create Database"**
4. Copy the **Internal Database URL**
5. Go back to your Web Service → **Environment** tab
6. Add environment variable:
   ```
   DATABASE_URL=<paste the internal database URL>
   ```
7. Save → Service will auto-redeploy
8. Check `/health` again - should show `"database": "connected"`

**Database Schema:**
The backend auto-creates tables on first connection (see `config/database.js`).

---

## 📱 Update iOS App

Now update your iOS app to use the production URL:

### Edit `iOS/Flirrt/Config/AppConstants.swift`:

```swift
var apiBaseURL: String {
    switch self {
    case .development:
        return "http://10.10.10.24:3000/api/v1"  // Keep for local dev
    case .staging:
        return "https://flirrt-api-production.onrender.com/api/v1"
    case .production:
        return "https://flirrt-api-production.onrender.com/api/v1"
    }
}
```

### Clean Up Local Network Code:

1. **Delete** `NSLocalNetworkUsageDescription` from `FlirrtKeyboard-Info.plist`
2. **Archive** `NETWORK_SETUP_INSTRUCTIONS.md` (no longer needed)
3. **Rebuild** app in Xcode:
   ```bash
   # Clean build folder
   Cmd+Shift+K in Xcode

   # Build and run on iPad
   Cmd+R
   ```

---

## ✅ Production Testing Checklist

### Backend Health:
- [ ] `/health` endpoint returns 200 OK
- [ ] All API keys show "configured"
- [ ] Environment shows "production"
- [ ] HTTPS working (no SSL errors)

### iOS Integration:
- [ ] App connects to Render URL
- [ ] No network timeout errors
- [ ] Screenshot upload works
- [ ] Flirt suggestions generated

### Feature Validation:
- [ ] **Complete Profile**: Returns 5 personalized flirt suggestions
- [ ] **Incomplete Profile**: Shows "scroll down" message + retry button
- [ ] **Empty Chat**: Asks to screenshot profile instead
- [ ] **Active Chat**: Generates conversation continuation replies
- [ ] **Network Error**: Shows retry button with user-friendly message

---

## 🔧 Deployment Management

### View Logs:
1. Go to Render Dashboard → Your Web Service
2. Click **"Logs"** tab
3. See real-time server logs
4. Filter by date/time/keyword

### Manual Deploy:
1. Go to Render Dashboard → Your Web Service
2. Click **"Manual Deploy"** → **"Deploy latest commit"**
3. Or push to GitHub (auto-deploys if enabled)

### Rollback:
1. Go to **"Events"** tab
2. Find previous successful deployment
3. Click **"Rollback to this deploy"**

### Environment Variables:
1. Click **"Environment"** tab
2. Add/Edit/Delete variables
3. Click **"Save Changes"**
4. Service auto-redeploys with new values

---

## 📊 Monitoring & Alerts

### Built-in Metrics:
- Go to **"Metrics"** tab to see:
  - CPU usage
  - Memory usage
  - Request count
  - Response times

### Set Up Alerts:
1. Go to **"Settings"** → **"Notifications"**
2. Add email or Slack webhook
3. Choose alert triggers:
   - Deploy failed
   - Service unhealthy
   - High error rate

### Uptime Monitoring:
- Render Team plan includes 99.9% uptime SLA
- Check **"Status"** page for incidents
- Configure external monitoring (e.g., UptimeRobot) for redundancy

---

## 🔒 Security Best Practices

1. **API Keys:**
   - ✅ Stored in Render environment variables (encrypted)
   - ❌ Never in git repository
   - ✅ Rotate keys periodically

2. **HTTPS:**
   - ✅ Automatic SSL/TLS certificates
   - ✅ Auto-renewal by Render
   - ✅ Enforced for all requests

3. **Rate Limiting:**
   - Uncomment `rateLimit()` middleware in production
   - Protect against abuse/DDoS

4. **CORS:**
   - Restrict to iOS app only (not wildcard `*`)
   - Update `config/constants.js` cors settings

---

## 💰 Cost Breakdown

### Render.com Team Plan:

| Service | Plan | Cost/Month |
|---------|------|------------|
| Web Service | Team | $19 |
| PostgreSQL | Free (dev) | $0 |
| PostgreSQL | Starter | $7 |
| **Total (API only)** | | **$19/month** |
| **Total (with DB)** | | **$26/month** |

**What You Get:**
- 99.9% uptime SLA
- Auto-scaling
- Automatic SSL
- Unlimited collaborators
- 10 GB bandwidth included
- Background workers
- Priority support

---

## 🆘 Troubleshooting

### Issue: Deployment Failed

**Check:**
1. Build logs for errors
2. Ensure `package.json` has all dependencies
3. Verify Node version compatibility (Render uses latest LTS)

**Fix:**
```bash
# Add .node-version file to specify version
echo "20" > .node-version
git add .node-version
git commit -m "Specify Node version for Render"
git push
```

### Issue: Health Check Failing

**Check:**
1. Server logs for startup errors
2. Environment variables configured correctly
3. `/health` endpoint accessible

**Fix:**
- Verify `PORT` environment variable set to `3000`
- Check `JWT_SECRET` meets minimum length (32 chars)
- Ensure API keys are configured

### Issue: iOS Can't Connect

**Check:**
1. iOS app using HTTPS URL (not HTTP)
2. No firewall blocking requests
3. Render service is "Live" (green status)

**Fix:**
```swift
// Verify AppConstants.swift has HTTPS URL
return "https://flirrt-api-production.onrender.com/api/v1"  // ✅ HTTPS
// NOT: "http://..." // ❌ Will fail on iOS
```

### Issue: High Response Times

**Check:**
1. Render metrics show CPU/memory usage
2. Grok API latency (external dependency)
3. Database queries (if enabled)

**Fix:**
- Upgrade to higher Render plan (more CPU/RAM)
- Add Redis caching for repeated requests
- Optimize Grok API calls (reduce image size)

---

## 🚢 Production Deployment Complete!

You now have:
- ✅ Backend deployed on Render.com with HTTPS
- ✅ Auto-deploy from GitHub enabled
- ✅ All API keys configured securely
- ✅ Health monitoring active
- ✅ iOS app ready to test on production

**Next Steps:**
1. Update iOS app with production URL
2. Rebuild and install on iPad
3. Test all 5 feature scenarios
4. Monitor logs for any errors
5. Celebrate! 🎉

**Your Production API:**
```
https://flirrt-api-production.onrender.com/api/v1
```

---

**Last Updated:** October 6, 2025
**Render Plan:** Team ($19/month)
**Status:** ✅ Production Ready

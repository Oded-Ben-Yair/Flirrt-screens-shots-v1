# CI/CD Setup for Vibe8

## Overview

Automated CI/CD pipeline using GitHub Actions and Fastlane for testing, building, and deploying the Vibe8 iOS app.

## GitHub Actions Workflow

**Location**: `.github/workflows/ci.yml`

### Triggers
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`

### Jobs

#### 1. Build and Test
- **Runs on**: macOS 14 (latest)
- **Matrix**: Tests on iOS 17.5 and 18.0
- **Steps**:
  1. Checkout code
  2. Select Xcode 15.4
  3. Cache Ruby gems and Swift packages
  4. Install dependencies (`bundle install`)
  5. Run tests (`fastlane test`)
  6. Build app (`fastlane build`)
  7. Upload test results and coverage
  8. Archive build artifacts

#### 2. SwiftLint
- **Runs on**: macOS 14
- **Purpose**: Code quality and style checking
- **Steps**:
  1. Checkout code
  2. Install SwiftLint via Homebrew
  3. Run SwiftLint with strict mode

### Artifacts
- Test results (per iOS version)
- Code coverage reports
- Build artifacts (.ipa, .dSYM)

## Fastlane Configuration

**Location**: `fastlane/`

### Available Lanes

#### `fastlane test`
Runs all unit and UI tests with code coverage.

```bash
bundle exec fastlane test
```

**Options**:
- `IOS_VERSION`: Target iOS version (default: 18.0)

#### `fastlane build`
Builds the app for testing (Debug configuration).

```bash
bundle exec fastlane build
```

#### `fastlane ci`
Runs both test and build (used by CI pipeline).

```bash
bundle exec fastlane ci
```

#### `fastlane beta`
Deploys a beta build to TestFlight.

```bash
bundle exec fastlane beta
```

**Steps**:
1. Increments build number
2. Builds Release configuration
3. Uploads to TestFlight (internal testers only initially)
4. Commits version bump

#### `fastlane release`
Submits app to App Store for review.

```bash
bundle exec fastlane release
```

**Steps**:
1. Increments version number (patch)
2. Builds Release configuration
3. Uploads to App Store Connect
4. Submits for review
5. Commits version bump
6. Creates git tag

#### `fastlane setup_match`
Sets up code signing with Fastlane Match.

```bash
bundle exec fastlane setup_match
```

## Required Environment Variables

Set these in GitHub Secrets and local `.env` file:

### GitHub Secrets
```
APPLE_ID              # Apple Developer account email
TEAM_ID               # Apple Developer Team ID
ITC_TEAM_ID           # App Store Connect Team ID
MATCH_GIT_URL         # Git repo for Fastlane Match certificates
MATCH_PASSWORD        # Encryption password for certificates
FASTLANE_PASSWORD     # Apple ID password (or app-specific password)
```

### Local `.env` File
Create `fastlane/.env`:

```bash
APPLE_ID="your-apple-id@example.com"
TEAM_ID="YOUR_TEAM_ID"
ITC_TEAM_ID="YOUR_ITC_TEAM_ID"
MATCH_GIT_URL="https://github.com/your-org/certificates"
MATCH_PASSWORD="your-secure-password"
FASTLANE_PASSWORD="your-apple-password"
```

**Note**: Never commit `.env` to version control!

## Code Signing with Fastlane Match

Fastlane Match manages certificates and provisioning profiles in a private Git repository.

### Initial Setup

1. Create a private Git repository for certificates
2. Run setup:
   ```bash
   bundle exec fastlane setup_match
   ```
3. Match will:
   - Generate/download certificates
   - Store encrypted in git repo
   - Install on local machine

### Using Match in CI

GitHub Actions will automatically use Match for builds:
```yaml
- name: Setup code signing
  run: bundle exec fastlane match appstore --readonly
  env:
    MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
```

## Local Development

### Prerequisites
```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Ruby (use system Ruby or rbenv)
# Install Bundler
gem install bundler
```

### Setup
```bash
cd ~/FlirrtAI

# Install dependencies
bundle install

# Run tests locally
bundle exec fastlane test

# Build app locally
bundle exec fastlane build
```

## Branch Protection Rules

Configured on GitHub repository:

- ✅ Require pull request reviews (1 reviewer minimum)
- ✅ Require status checks to pass before merging
  - `build-and-test (17.5)`
  - `build-and-test (18.0)`
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Do not allow bypassing the above settings

## Testing Requirements

All pull requests must:
- Pass all unit tests
- Pass all UI tests
- Maintain 80%+ code coverage
- Pass SwiftLint checks
- Build successfully on both iOS 17.5 and 18.0

## Deployment Process

### TestFlight (Beta)
```bash
# Ensure you're on develop branch
git checkout develop
git pull origin develop

# Deploy to TestFlight
bundle exec fastlane beta

# This will:
# 1. Increment build number
# 2. Build Release configuration
# 3. Upload to TestFlight
# 4. Commit version bump
```

### App Store (Production)
```bash
# Merge develop to main
git checkout main
git merge develop
git push origin main

# Deploy to App Store
bundle exec fastlane release

# This will:
# 1. Increment version number
# 2. Build Release configuration
# 3. Submit for App Store review
# 4. Create git tag
```

## Monitoring

### GitHub Actions
- View workflow runs: https://github.com/YOUR_ORG/FlirrtAI/actions
- Check build status, logs, artifacts

### App Store Connect
- TestFlight builds: https://appstoreconnect.apple.com/apps/{app_id}/testflight
- App Store submissions: https://appstoreconnect.apple.com/apps/{app_id}/appstore

## Troubleshooting

### Build fails on CI but passes locally
- Check Xcode version matches (CI uses 15.4)
- Verify iOS simulator version
- Check for environment-specific issues

### Code signing issues
```bash
# Reset Match
bundle exec fastlane match nuke development
bundle exec fastlane match nuke distribution
bundle exec fastlane setup_match
```

### TestFlight upload fails
- Verify certificates are valid
- Check App Store Connect API access
- Ensure build number is incremented

---

This CI/CD setup ensures every code change is tested, quality-checked, and ready for deployment to TestFlight or App Store.

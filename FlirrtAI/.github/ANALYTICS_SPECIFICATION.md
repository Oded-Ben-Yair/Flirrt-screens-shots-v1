# Vibe8 v2.0 - Analytics Tracking Specification
**Analytics Implementation Guide for Gamification Features**

---

## Overview

This document specifies all analytics events to track in Vibe8 v2.0, focusing on gamification features while maintaining user privacy. All tracking is **optional** and controlled via Settings.

**Privacy-First Approach**:
- ✅ Analytics is **OPT-IN** via Settings
- ✅ No Personally Identifiable Information (PII) tracked
- ✅ All events are anonymous
- ✅ Local gamification data (points, streaks) **NEVER** transmitted to analytics
- ✅ GDPR/CCPA compliant

---

## Recommended Platform

**Firebase Analytics** (Free, iOS native, privacy-compliant)

**Alternatives**:
- Mixpanel (more advanced funnels, paid)
- Amplitude (good for retention analysis, paid)
- PostHog (open-source, self-hosted option)

**Why Firebase**:
- Free tier sufficient for beta + initial launch
- Native iOS SDK with SwiftUI support
- Automatic screen tracking
- Built-in crash reporting (Crashlytics)
- Easy Google Analytics integration for web marketing
- Privacy controls (IP anonymization, data retention settings)

---

## Event Categories

1. **Core Feature Events** - Screenshot analysis, flirt generation
2. **Gamification Events** - Points, streaks, milestones, tiers
3. **User Engagement Events** - App opens, session duration, retention
4. **Monetization Events** - (Future) In-app purchases, premium tiers
5. **Onboarding Events** - Tutorial completion, first actions
6. **Error Events** - Failed API calls, user-facing errors

---

## Event Naming Convention

**Format**: `category_action_detail`

**Examples**:
- `screenshot_upload_success`
- `gamification_flirt_revealed`
- `milestone_achieved_explorer`
- `settings_toggle_gamification_on`

**Rules**:
- All lowercase
- Underscores for separation
- Max 40 characters
- Descriptive but concise

---

## Event Specifications

### 1. Core Feature Events

#### `screenshot_upload_initiated`
**When**: User taps "Analyze Screenshot" and photo picker appears
**Properties**:
```swift
[
  "source": String, // "photo_library" | "camera"
  "session_id": String // Unique session identifier
]
```
**Why Track**: Understand upload source preference

---

#### `screenshot_upload_success`
**When**: Screenshot successfully uploaded to backend
**Properties**:
```swift
[
  "image_size_kb": Int, // File size in KB
  "upload_duration_ms": Int, // Time to upload
  "session_id": String
]
```
**Why Track**: Monitor upload performance, identify slow uploads

---

#### `screenshot_upload_failed`
**When**: Screenshot upload fails
**Properties**:
```swift
[
  "error_code": String, // "network_error", "invalid_image", "timeout"
  "error_message": String, // Sanitized error (no PII)
  "retry_attempt": Int, // 1, 2, 3, etc.
  "session_id": String
]
```
**Why Track**: Identify failure patterns, improve error handling

---

#### `screenshot_analysis_started`
**When**: Gemini analysis begins
**Properties**:
```swift
[
  "tone_selected": String, // "playful", "sincere", "witty", "bold", "casual"
  "session_id": String
]
```
**Why Track**: Understand tone preference distribution

---

#### `screenshot_analysis_completed`
**When**: Gemini analysis completes successfully
**Properties**:
```swift
[
  "analysis_duration_ms": Int, // Time Gemini took
  "tone_selected": String,
  "session_id": String
]
```
**Why Track**: Monitor Gemini performance

---

#### `screenshot_analysis_failed`
**When**: Gemini analysis fails
**Properties**:
```swift
[
  "error_code": String, // "api_error", "timeout", "invalid_response"
  "error_message": String,
  "retry_attempt": Int,
  "session_id": String
]
```
**Why Track**: Identify Gemini API issues

---

#### `flirt_generation_started`
**When**: GPT-5 generation begins
**Properties**:
```swift
[
  "tone_selected": String,
  "session_id": String
]
```
**Why Track**: Track generation requests

---

#### `flirt_generation_completed`
**When**: All 3 flirts generated successfully
**Properties**:
```swift
[
  "generation_duration_ms": Int, // Time GPT-5 took
  "tone_selected": String,
  "flirt_count": Int, // Should be 3
  "session_id": String
]
```
**Why Track**: Monitor GPT-5 performance

---

#### `flirt_generation_failed`
**When**: GPT-5 generation fails
**Properties**:
```swift
[
  "error_code": String,
  "error_message": String,
  "retry_attempt": Int,
  "session_id": String
]
```
**Why Track**: Identify GPT-5 API issues

---

### 2. Gamification Events

#### `gamification_flirt_revealed`
**When**: User scrolls and fully reveals a blurred flirt
**Properties**:
```swift
[
  "reveal_method": String, // "scroll" (v2.0 only, future: "ad_watched", "points_spent")
  "scroll_duration_ms": Int, // Time from start to full reveal
  "flirt_index": Int, // 0, 1, 2 (primary, alternative 1, alternative 2)
  "session_id": String
]
```
**Why Track**: Understand scroll-to-reveal engagement

**Privacy Note**: Does NOT track flirt content, only metadata

---

#### `gamification_points_awarded`
**When**: User earns points (any action)
**Properties**:
```swift
[
  "action": String, // "scroll_reveal", "copy_flirt", "rate_flirt", "generate_flirts", "daily_login"
  "points_earned": Int, // Base points before multiplier
  "multiplier": Double, // 1.0, 2.0, or 3.0
  "total_points_after": Int, // New balance (binned for privacy)
  "session_id": String
]
```
**Why Track**: Monitor points economy balance, identify most engaging actions

**Privacy Note**: `total_points_after` is binned (0-100, 101-500, 501-1000, 1001-5000, 5000+) to avoid fingerprinting

---

#### `gamification_flirt_copied`
**When**: User taps copy button on a flirt
**Properties**:
```swift
[
  "flirt_index": Int, // 0, 1, 2
  "tone_used": String,
  "quality_tier": String, // "bronze", "silver", "gold", "platinum"
  "session_id": String
]
```
**Why Track**: Understand which flirts users actually use, quality tier effectiveness

**Privacy Note**: Does NOT track flirt content

---

#### `gamification_flirt_rated`
**When**: User rates a flirt with stars
**Properties**:
```swift
[
  "rating": Int, // 1-5 stars
  "flirt_index": Int,
  "tone_used": String,
  "quality_tier": String,
  "session_id": String
]
```
**Why Track**: Measure flirt quality, improve AI prompts

---

#### `gamification_streak_updated`
**When**: Streak changes (increments, resets, freeze used)
**Properties**:
```swift
[
  "previous_streak": Int,
  "new_streak": Int,
  "change_type": String, // "increment", "reset", "freeze_used"
  "multiplier_before": Double,
  "multiplier_after": Double,
  "session_id": String
]
```
**Why Track**: Monitor streak engagement, freeze usage patterns

---

#### `gamification_milestone_achieved`
**When**: User achieves a milestone (10, 50, 100 flirts)
**Properties**:
```swift
[
  "milestone_type": String, // "explorer", "connoisseur", "master"
  "flirts_revealed_count": Int, // 10, 50, or 100
  "reward_points": Int, // 100, 500, or 1500
  "days_since_install": Int,
  "session_id": String
]
```
**Why Track**: Measure progression speed, retention correlation

---

#### `gamification_tier_unlocked`
**When**: User unlocks a new quality tier
**Properties**:
```swift
[
  "tier_unlocked": String, // "silver", "gold", "platinum"
  "unlock_method": String, // "flirts_revealed", "points_spent", "streak_achieved"
  "flirts_revealed_count": Int,
  "current_streak": Int,
  "days_since_install": Int,
  "session_id": String
]
```
**Why Track**: Understand tier progression paths, balance unlock requirements

---

#### `gamification_tutorial_step_viewed`
**When**: User views a tutorial step
**Properties**:
```swift
[
  "step_number": Int, // 1, 2, 3
  "step_title": String, // "Scroll to Reveal", "Earn Points", "Build Your Streak"
  "session_id": String
]
```
**Why Track**: Monitor tutorial completion rates

---

#### `gamification_tutorial_completed`
**When**: User completes full tutorial
**Properties**:
```swift
[
  "completion_time_seconds": Int, // Time to complete all 3 steps
  "skipped": Bool, // true if user skipped
  "session_id": String
]
```
**Why Track**: Measure onboarding effectiveness

---

#### `gamification_tutorial_skipped`
**When**: User skips tutorial
**Properties**:
```swift
[
  "step_skipped_on": Int, // Which step they were on when skipping (1, 2, 3)
  "session_id": String
]
```
**Why Track**: Identify confusing/boring tutorial steps

---

### 3. Settings Events

#### `settings_gamification_toggled`
**When**: User enables/disables gamification in Settings
**Properties**:
```swift
[
  "new_state": String, // "enabled" | "disabled"
  "days_since_install": Int,
  "total_flirts_revealed": Int, // Binned (0-10, 11-50, 51-100, 100+)
  "session_id": String
]
```
**Why Track**: Understand how many users disable gamification, when they do it

---

#### `settings_data_exported`
**When**: User exports gamification data
**Properties**:
```swift
[
  "export_format": String, // "json" (v2.0), future: "csv", "pdf"
  "session_id": String
]
```
**Why Track**: Measure data portability usage

---

#### `settings_data_deleted`
**When**: User deletes all gamification data
**Properties**:
```swift
[
  "days_since_install": Int,
  "total_points_binned": String, // "0-100", "101-500", etc.
  "session_id": String
]
```
**Why Track**: Understand churn signals

---

### 4. User Engagement Events

#### `app_opened`
**When**: App launches (foreground from background or cold start)
**Properties**:
```swift
[
  "launch_type": String, // "cold_start" | "background_resume"
  "days_since_install": Int,
  "days_since_last_open": Int, // 0 = same day, 1 = next day, etc.
  "session_id": String
]
```
**Why Track**: Daily Active Users (DAU), retention

---

#### `session_started`
**When**: User begins a new session
**Properties**:
```swift
[
  "session_id": String,
  "time_of_day": String, // "morning", "afternoon", "evening", "night"
  "day_of_week": String // "monday", "tuesday", etc.
]
```
**Why Track**: Identify peak usage times

---

#### `session_ended`
**When**: User backgrounds app or quits
**Properties**:
```swift
[
  "session_duration_seconds": Int,
  "screens_visited": Int, // How many screens navigated
  "flirts_generated": Int, // How many flirt sets generated this session
  "session_id": String
]
```
**Why Track**: Engagement depth, session quality

---

### 5. Error Events

#### `error_displayed`
**When**: User sees an error message
**Properties**:
```swift
[
  "error_type": String, // "network_error", "api_error", "validation_error"
  "error_code": String,
  "screen": String, // Which screen error occurred on
  "session_id": String
]
```
**Why Track**: Identify UX friction points

---

## Implementation Guide

### Step 1: Install Firebase SDK

**Add to `Podfile`**:
```ruby
pod 'Firebase/Analytics'
pod 'Firebase/Crashlytics'
```

**Or Swift Package Manager**:
```
https://github.com/firebase/firebase-ios-sdk
```

### Step 2: Initialize in AppDelegate

```swift
import Firebase

@main
struct Vibe8App: App {
    init() {
        FirebaseApp.configure()

        // Enable analytics only if user has opted in
        if UserDefaults.standard.bool(forKey: "analytics.enabled") {
            Analytics.setAnalyticsCollectionEnabled(true)
        } else {
            Analytics.setAnalyticsCollectionEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Step 3: Create Analytics Manager

```swift
import FirebaseAnalytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()

    private var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "analytics.enabled")
    }

    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard isEnabled else { return }

        // Add session_id to all events
        var params = parameters ?? [:]
        params["session_id"] = sessionId

        Analytics.logEvent(name, parameters: params)
    }

    private var sessionId: String {
        // Generate unique session ID on app launch
        if let existingId = UserDefaults.standard.string(forKey: "current_session_id") {
            return existingId
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "current_session_id")
        return newId
    }

    func startNewSession() {
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "current_session_id")
    }
}
```

### Step 4: Usage Examples

**Flirt Revealed**:
```swift
// In FlirtCardWithReveal.swift
private func handleFullReveal() {
    AnalyticsManager.shared.logEvent("gamification_flirt_revealed", parameters: [
        "reveal_method": "scroll",
        "scroll_duration_ms": Int(scrollDuration * 1000),
        "flirt_index": flirtIndex
    ])
}
```

**Points Awarded**:
```swift
// In GamificationModel.swift
func awardPoints(for action: PointAction) {
    let pointsEarned = action.pointValue
    let multiplier = streakMultiplier
    let finalPoints = Int(Double(pointsEarned) * multiplier)

    totalPoints += finalPoints

    AnalyticsManager.shared.logEvent("gamification_points_awarded", parameters: [
        "action": action.rawValue,
        "points_earned": pointsEarned,
        "multiplier": multiplier,
        "total_points_after": binnedPoints(totalPoints)
    ])
}

private func binnedPoints(_ points: Int) -> String {
    switch points {
    case 0...100: return "0-100"
    case 101...500: return "101-500"
    case 501...1000: return "501-1000"
    case 1001...5000: return "1001-5000"
    default: return "5000+"
    }
}
```

**Milestone Achieved**:
```swift
// In GamificationModel.swift
func checkMilestones() -> Milestone? {
    guard let milestone = getNextMilestone() else { return nil }

    achievedMilestones.insert(milestone.type)

    AnalyticsManager.shared.logEvent("gamification_milestone_achieved", parameters: [
        "milestone_type": milestone.type.rawValue,
        "flirts_revealed_count": flirtsRevealedCount,
        "reward_points": milestone.reward.points,
        "days_since_install": daysSinceInstall
    ])

    return milestone
}
```

### Step 5: Privacy Controls in Settings

```swift
// SettingsView.swift
SettingsToggleRow(
    icon: "chart.bar.fill",
    title: "Anonymous Analytics",
    description: "Help improve Vibe8 with usage data (no personal info)",
    isOn: $analyticsEnabled,
    color: .blue
)
.onChange(of: analyticsEnabled) { _, newValue in
    UserDefaults.standard.set(newValue, forKey: "analytics.enabled")
    Analytics.setAnalyticsCollectionEnabled(newValue)

    AnalyticsManager.shared.logEvent("settings_analytics_toggled", parameters: [
        "new_state": newValue ? "enabled" : "disabled"
    ])
}
```

---

## Privacy Compliance Checklist

- [ ] **Opt-In by Default**: Analytics disabled until user explicitly enables
- [ ] **Clear Disclosure**: Settings description explains what's tracked
- [ ] **No PII**: Never track names, emails, photos, or flirt content
- [ ] **Data Minimization**: Only track what's necessary for improvement
- [ ] **Binning**: Aggregate metrics (points, flirts) into ranges to prevent fingerprinting
- [ ] **IP Anonymization**: Enable in Firebase Console (Settings → Data Collection → IP anonymization)
- [ ] **Data Retention**: Set to 14 months in Firebase Console (default is indefinite)
- [ ] **User Rights**: Provide export/delete functionality in Settings
- [ ] **Privacy Policy**: Update with analytics disclosure
- [ ] **App Store Disclosure**: Declare analytics in App Store Connect (Data Types → Analytics)

---

## Dashboard Metrics to Monitor

### Key Performance Indicators (KPIs)

**Engagement**:
- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Average session duration
- Sessions per user per day

**Gamification**:
- % users with gamification enabled
- Average flirts revealed per user
- Streak distribution (1 day, 3 days, 7+ days)
- Milestone achievement rates (10, 50, 100 flirts)
- Quality tier unlock rates

**Core Features**:
- Screenshot upload success rate
- Average upload duration
- Gemini analysis success rate
- GPT-5 generation success rate
- Flirt copy rate (% of generated flirts copied)

**Retention**:
- Day 1 retention
- Day 7 retention
- Day 30 retention
- Churn signals (analytics disabled, data deleted)

**Errors**:
- Error rate by type
- Most common error codes
- Error impact on user sessions

---

## Firebase Console Setup

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project"
3. Name: "Vibe8 Production"
4. Enable Google Analytics: YES
5. Choose Analytics account: Create new or use existing

### 2. Add iOS App
1. Click "Add app" → iOS
2. Bundle ID: `com.vibe8.app` (or your actual bundle ID)
3. Download `GoogleService-Info.plist`
4. Add to Xcode project (root, not folder)

### 3. Configure Privacy
1. Settings → Data Collection
   - IP anonymization: ON
   - Personalized ads: OFF (not relevant for Vibe8)
   - Data retention: 14 months
2. Settings → User Data Deletion
   - Enable data deletion on request: YES

### 4. Create Custom Events
1. Analytics → Events → "Manage Custom Definitions"
2. Add all events from this spec as custom events
3. Mark parameters as "Custom dimensions" for filtering

---

## Testing Analytics

### 1. Debug Mode (During Development)

**Enable debug mode in Xcode**:
```swift
// AppDelegate or App init
#if DEBUG
Analytics.setAnalyticsCollectionEnabled(true)
// Enable debug logging
Analytics.setUserProperty("true", forName: "debug_mode")
#endif
```

**Or via command line**:
```bash
# Enable debug mode for specific device
xcrun simctl launch booted -FIRDebugEnabled

# Disable debug mode
xcrun simctl launch booted -FIRDebugDisabled
```

### 2. DebugView in Firebase Console

1. Firebase Console → Analytics → DebugView
2. Events appear in real-time during testing
3. Verify event names and parameters

### 3. Test Checklist

- [ ] Opt-in/opt-out works (events stop when disabled)
- [ ] All events fire with correct parameters
- [ ] No PII in any event (names, emails, content)
- [ ] Session IDs are unique per session
- [ ] Binned values are ranges, not exact numbers
- [ ] Error events capture useful debugging info

---

## Example Analytics Dashboard

**Week 1 Post-Launch**:
```
DAU: 250 users
WAU: 850 users
Average session: 4.2 minutes

Gamification:
- Enabled: 92% (230/250 users)
- Average flirts revealed per user: 8.5
- Streak retention:
  - Day 1: 100% (250 users)
  - Day 3: 68% (170 users)
  - Day 7: 42% (105 users)

Milestones:
- Explorer (10 flirts): 35% (88 users)
- Connoisseur (50 flirts): 0% (week 1)
- Master (100 flirts): 0% (week 1)

Core Features:
- Upload success rate: 97.5%
- Average upload time: 2.1s
- Gemini success rate: 99.2%
- GPT-5 success rate: 98.8%
- Flirt copy rate: 42% (users copy 1.3/3 flirts on average)

Errors:
- Network errors: 2.1% of requests
- API timeouts: 0.3% of requests
```

---

## Next Steps

1. **Phase 4 Testing**: Implement analytics in dev environment
2. **TestFlight Beta**: Monitor analytics from beta testers
3. **Launch Day**: Watch for anomalies, crashes, error spikes
4. **Week 1**: Review retention, engagement, gamification adoption
5. **Month 1**: Optimize based on data (adjust points economy, unlock requirements)

---

**Questions?** Email: analytics@vibe8.app

**Last Updated**: November 1, 2025
**Vibe8 Team**

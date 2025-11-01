# Vibe8 v2.0 - TestFlight Beta Testing Guide
**Welcome, Beta Testers!**

Thank you for helping us test Vibe8 version 2.0 before it goes live on the App Store. Your feedback is invaluable!

---

## What's New in v2.0

🎮 **Major Update**: We've added a complete gamification system that makes improving your dating skills fun and engaging!

**New Features to Test**:
- Scroll-to-reveal mechanics for flirts
- Points and rewards system
- Daily streak tracking with multipliers
- Achievement milestones
- Interactive tutorial for first-time users
- Settings toggle to enable/disable gamification

---

## Getting Started

### 1. Install via TestFlight
- Check your email for the TestFlight invitation
- Tap "View in TestFlight" or "Start Testing"
- Install Vibe8 v2.0 from TestFlight app
- **Important**: Delete any old version of Flirrt/Vibe8 first to start fresh

### 2. First Launch
- Open Vibe8
- You'll see a 3-step tutorial (please don't skip it the first time!)
- Grant any permissions requested (photo library access for screenshots)
- Tutorial explains scroll-to-reveal, points system, and streaks

### 3. Try the Core Flow
1. Tap "Analyze Screenshot"
2. Upload a dating app screenshot (we've provided samples below)
3. Select a tone (try "Playful" first)
4. Tap "Generate Flirts"
5. **NEW**: Scroll down to reveal each flirt progressively
6. Watch points accumulate in the HUD at the top
7. Copy a flirt to earn 25 bonus points
8. Rate flirts with stars to help us improve

---

## Sample Screenshots to Test With

### Option 1: Tinder Profile
- Use any Tinder screenshot from your own app
- Make sure profile photo and bio are visible
- Best results with clear, high-quality screenshots

### Option 2: Bumble Profile
- Similar to Tinder, any Bumble screenshot works
- Bio text helps AI generate more personalized flirts

### Option 3: Test Image (Provided)
- Check TestFlight notes for a sample screenshot we've provided
- Good for testing without needing a real dating app

---

## What to Test

### 🎯 Priority 1: Critical Features

#### Gamification Mechanics
- [ ] **Scroll-to-reveal works smoothly**
  - Flirts start blurred
  - Scrolling gradually reveals them
  - Animation is smooth (no jank or stuttering)
  - Progress indicator shows % revealed

- [ ] **Points system working correctly**
  - Revealing a flirt awards 10 points
  - Copying awards 25 points
  - Rating 4-5 stars awards 50 points
  - Points display updates in HUD immediately

- [ ] **Streak tracking accurate**
  - Open app tomorrow and check if streak increments to 2
  - Flame icon shows in HUD
  - Multiplier badge appears at 3+ day streak

- [ ] **Milestones trigger correctly**
  - Reveal 10 flirts → "Explorer" celebration appears
  - Celebration auto-dismisses after ~3 seconds
  - 100 bonus points added to balance

#### Core Features (existing)
- [ ] **Screenshot upload works**
  - Photo picker opens
  - Image uploads successfully
  - Preview shows selected screenshot

- [ ] **AI analysis completes**
  - Gemini analyzes screenshot (may take 3-5 seconds)
  - Analysis results appear

- [ ] **Flirt generation works**
  - GPT-5 generates 3 flirts
  - Different tones produce different styles
  - Quality scores display (sentiment, creativity, etc.)

### 🎨 Priority 2: UI/UX Polish

- [ ] **Tutorial experience**
  - Tutorial shows on first launch only
  - Can skip tutorial
  - Clear and helpful messaging
  - Never shows again after completion

- [ ] **Settings toggle**
  - Navigate to Settings → App Preferences
  - Toggle "Gamification" off
  - Flirts show instantly without blur
  - HUD disappears
  - Toggle back on and everything returns

- [ ] **Visual design**
  - Vibe8 gradient looks good
  - Cards are readable
  - HUD doesn't obstruct content
  - Animations feel premium

### ⚡ Priority 3: Performance

- [ ] **Scroll performance**
  - Scrolling feels smooth at 60fps
  - No stuttering or lag during reveal
  - Blur effect performs well
  - App doesn't overheat device

- [ ] **Battery usage**
  - App doesn't drain battery excessively
  - No unusual heat from device
  - Background refresh doesn't run constantly

- [ ] **Memory usage**
  - App doesn't crash with multiple screenshots
  - Can generate 10+ sets of flirts without issues
  - Switching apps and returning works smoothly

### 🐛 Priority 4: Edge Cases

- [ ] **Poor quality screenshots**
  - Upload a very blurry screenshot
  - Upload a screenshot with no text
  - Upload a screenshot with no person visible
  - App should handle gracefully (don't crash)

- [ ] **App lifecycle**
  - Force quit app → reopen (points should persist)
  - Put app in background → return (state preserved)
  - Restart device → open app (streak should remember last date)

- [ ] **Network issues**
  - Turn on airplane mode
  - Try to generate flirts
  - App should show clear error message

---

## How to Report Bugs

### Using TestFlight Feedback
1. Shake your device while in Vibe8
2. TestFlight screenshot tool appears
3. Annotate the screenshot if helpful
4. Write description of the issue
5. Submit

**OR**

### Via Email
Send to: beta@vibe8.app

**Please include**:
- Device model (iPhone 15 Pro, iPhone 12, etc.)
- iOS version (17.5, 18.0, etc.)
- Steps to reproduce the bug
- Screenshots/screen recording if possible
- What you expected vs. what happened

---

## Feedback We're Looking For

### Specific Questions

1. **Gamification Fun Factor** (1-5 scale)
   - How fun is the scroll-to-reveal mechanic?
   - Do points/streaks motivate you to return daily?
   - Are milestones satisfying to achieve?

2. **Tutorial Effectiveness**
   - Did you understand how to use gamification after the tutorial?
   - Was anything confusing?
   - Should we add/remove any steps?

3. **Performance**
   - Does scrolling feel smooth?
   - Any lag or stuttering?
   - Device getting warm?

4. **Settings Toggle**
   - Did you try disabling gamification?
   - Prefer it on or off?
   - Why?

5. **Overall Experience**
   - Would you recommend v2.0 to friends?
   - What's your favorite new feature?
   - What would you change?

### General Feedback

**What we want to know**:
- What delights you?
- What frustrates you?
- What's confusing?
- What's missing?
- What should we prioritize next?

**Be brutally honest!** We want to fix issues before App Store launch.

---

## Testing Timeline

### Week 1 (Nov 1-7)
- **Focus**: Core functionality, critical bugs
- **Goal**: Catch show-stopper issues

### Week 2 (Nov 8-14)
- **Focus**: Performance, edge cases
- **Goal**: Polish and optimize

### Submission Target: Nov 15
- Internal testing complete
- Major bugs fixed
- Ready for App Store review

---

## Known Issues (Work in Progress)

We're aware of these issues and working on fixes:

1. ~~Blur effect occasionally glitches on iPhone 11~~ → FIXED in build 2
2. ~~Points don't persist after force quit~~ → FIXED in build 3
3. Tutorial sometimes shows twice → Investigating
4. Milestone celebration overlaps with HUD on small screens → Fix in progress

If you encounter these, no need to report—we're on it!

---

## Beta Tester Perks

As a thank-you for your help:

🎁 **Exclusive Rewards**:
- 5,000 bonus points when v2.0 launches (applies to your production account)
- Early access to v2.1 features
- Beta tester badge in-app (coming in v2.1)
- Credit in release notes (opt-in)

💌 **Stay Connected**:
- Join our private Discord for beta testers: [Link in email]
- Get weekly updates on development
- Vote on feature priorities

---

## FAQ for Beta Testers

**Q: How long is the beta test?**
A: 2 weeks (Nov 1-14, 2025)

**Q: Will my data carry over to production?**
A: No, TestFlight is a separate sandbox. You'll start fresh when v2.0 launches. But we'll credit you 5,000 bonus points!

**Q: Can I share screenshots/videos of the beta?**
A: Please don't share publicly until launch. Private feedback to us is encouraged!

**Q: What if I find a security issue?**
A: Email security@vibe8.app immediately. Do not report via public channels.

**Q: Can I test on multiple devices?**
A: Yes! Please do. Different devices may reveal different issues.

**Q: Do I need to test every day?**
A: Not required, but testing daily helps us verify streak functionality!

**Q: What's after v2.0?**
A: v2.1 will add CloudKit sync, social features, and more achievements. Beta testers get early access!

---

## Test Scenarios Checklist

Copy this into your notes and check off as you test:

**Day 1**:
- [ ] Install app and complete tutorial
- [ ] Upload first screenshot and generate flirts
- [ ] Scroll to reveal all 3 flirts
- [ ] Copy one flirt (earn 25 points)
- [ ] Rate flirts with stars
- [ ] Check points balance in HUD
- [ ] Close app and reopen (verify points persist)

**Day 2**:
- [ ] Open app (streak should increment to 2)
- [ ] Generate another set of flirts
- [ ] Reveal 10 total flirts (trigger Explorer milestone)
- [ ] Watch celebration animation
- [ ] Verify 100 bonus points added
- [ ] Toggle gamification off in Settings
- [ ] Generate flirts without gamification
- [ ] Toggle back on

**Day 3**:
- [ ] Open app (streak should be 3, 2x multiplier!)
- [ ] Verify multiplier badge shows in HUD
- [ ] Earn points and confirm they're 2x
- [ ] Try all 5 tone options
- [ ] Upload 5 different screenshots
- [ ] Test with poor quality image

**Day 4+**:
- [ ] Continue building streak
- [ ] Test streak freeze (skip a day intentionally after Day 5)
- [ ] Verify streak doesn't break with freeze
- [ ] Work toward Connoisseur milestone (50 flirts)
- [ ] Stress test: Generate 20+ sets of flirts

---

## Thank You!

Your participation makes Vibe8 better for everyone. We can't wait to hear your feedback!

**Questions?** Reply to the TestFlight invitation email or reach out to beta@vibe8.app.

**Let's make dating apps less stressful and more fun!** 🎮✨

---

**Vibe8 Team**
November 2025

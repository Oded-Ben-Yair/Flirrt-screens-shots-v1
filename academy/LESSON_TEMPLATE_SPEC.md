# Seekapa Trading Academy - Lesson Template Specification

**Version**: 1.0
**Based on**: lesson-01-interactive.html (1,406 lines)
**Last Updated**: November 11, 2025

---

## Overview

This document specifies the exact structure, styling, and content patterns that ALL lessons must follow for consistency across Seekapa Trading Academy.

---

## File Structure (Per Lesson)

```
lesson-{N}/
├── lesson-{N}-interactive.html          # Main lesson file (1,200-1,500 lines)
├── lesson-{N}-content-4lang.json        # Translation manifest (72 strings × 4 languages)
├── images/                              # 8-9 professional images
│   ├── {N:02d}_01_{title_slug}.png     # Hero/intro image
│   ├── {N:02d}_02_{title_slug}.png     # Concept visualization
│   ├── {N:02d}_03_{title_slug}.png     # Section 1 illustration
│   ├── {N:02d}_04_{title_slug}.png     # Section 2 illustration
│   ├── {N:02d}_05_{title_slug}.png     # Section 3 illustration
│   ├── {N:02d}_06_{title_slug}.png     # Section 4 illustration
│   ├── {N:02d}_07_{title_slug}.png     # Exercise/takeaways visual
│   ├── {N:02d}_08_{title_slug}.png     # Next lesson teaser
│   └── Seekapa Black Logo.png          # (symlink to shared/images/)
└── research/                            # (optional) Research notes
```

---

## HTML Structure

### 1. Document Head

**MUST include:**
```html
<!DOCTYPE html>
<html lang="ar" dir="rtl">  <!-- Default: Arabic RTL -->
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="Seekapa Trading Academy - Lesson {N}: {Title}">

    <!-- Multi-language alternate links -->
    <link rel="alternate" hreflang="ar" href="/ar/lesson-{N}" />
    <link rel="alternate" hreflang="en" href="/en/lesson-{N}" />
    <link rel="alternate" hreflang="es" href="/es/lesson-{N}" />
    <link rel="alternate" hreflang="pt" href="/pt/lesson-{N}" />

    <title>الدرس {N}: {Arabic Title} | Seekapa Trading Academy</title>

    <!-- Premium Typography (EXACT fonts from lesson-01) -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin">
    <link href="https://fonts.googleapis.com/css2?family=Noto+Kufi+Arabic:wght@400;500;600;700&family=Cairo:wght@600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@600;700&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
</head>
```

### 2. CSS Variables (MUST preserve exactly)

**Color Palette:**
```css
:root {
    /* Seekapa Brand Colors */
    --seekapa-forest: #1B5E3F;        /* Primary brand */
    --seekapa-emerald: #0F5F3F;       /* Dark accent */
    --seekapa-sage: #7A9D8E;          /* Light accent */
    --trust-navy: #1F3A6B;            /* Trust blue */
    --burgundy: #8B3A3A;              /* Accent red */
    --champagne-gold: #D4AF37;        /* Premium gold */
    --platinum: #E5E4E2;              /* Light gray */
    --charcoal: #2B2D42;              /* Text primary */
    --slate: #8D99AE;                 /* Text secondary */
    --pearl: #F8F9FA;                 /* Background light */
    --ivory: #FDFDF8;                 /* Background cream */

    /* Gamification Colors */
    --xp-blue: #3B82F6;               /* XP progress */
    --badge-gold: #FFD700;            /* Achievement badges */
    --streak-orange: #FF6B35;         /* Streak counter */
    --correct-green: #10B981;         /* Correct answer */
    --incorrect-red: #EF4444;         /* Incorrect answer */
}
```

**Typography Scale:**
```css
:root {
    --font-size-base: 18px;           /* Base text */
    --font-size-lg: 1.25rem;          /* Large text */
    --font-size-xl: 1.75rem;          /* Headings */
    --font-size-2xl: 2.25rem;         /* Section titles */
    --font-size-3xl: 3.5rem;          /* Hero titles */
}
```

### 3. Body Structure

```html
<body>
    <!-- Top Progress Bar -->
    <div class="progress-container">
        <div class="progress-bar" id="progressBar"></div>
    </div>

    <!-- Language & Navigation Header -->
    <header class="navbar">
        <div class="nav-content">
            <div class="logo-section">
                <img src="images/Seekapa Black Logo.png" alt="Seekapa" class="logo">
                <span class="academy-name" data-translate="academy_name">أكاديمية سيكابا للتداول</span>
            </div>

            <!-- Language Switcher (4 languages) -->
            <div class="language-switcher">
                <button class="lang-btn" data-lang="ar">العربية</button>
                <button class="lang-btn" data-lang="en">English</button>
                <button class="lang-btn" data-lang="es">Español</button>
                <button class="lang-btn" data-lang="pt">Português</button>
            </div>

            <!-- Gamification Stats -->
            <div class="gamification-header">
                <div class="xp-display">
                    <span class="xp-icon">⚡</span>
                    <span id="xpAmount">0</span> XP
                </div>
                <div class="streak-display">
                    <span class="streak-icon">🔥</span>
                    <span id="streakCount">0</span> days
                </div>
            </div>
        </div>
    </header>

    <!-- Main Content Container -->
    <main class="lesson-container">
        <!-- Lesson Progress (e.g., "Lesson 2 of 12") -->
        <div class="lesson-progress">
            <span data-translate="lesson_number">الدرس {N} من 12</span>
        </div>

        <!-- Lesson Title Section -->
        <section class="hero-section">
            <h1 class="hero-title" data-translate="title">{Arabic Title}</h1>
            <p class="hero-subtitle" data-translate="subtitle">{Arabic Subtitle}</p>
        </section>

        <!-- Video Section (Placeholder) -->
        <section class="video-section">
            <div class="video-container">
                <div class="video-placeholder">
                    <div class="play-icon">▶</div>
                    <p data-translate="video_coming_soon">الفيديو قيد الإعداد</p>
                    <p class="video-details">المدة: دقيقتان | الجودة: 1080p</p>
                </div>
            </div>
        </section>

        <!-- Learning Objectives -->
        <section class="objectives-section">
            <h2 data-translate="objectives_title">أهداف التعلم</h2>
            <ul class="objectives-list">
                <li data-translate="objective_1">{Objective 1}</li>
                <li data-translate="objective_2">{Objective 2}</li>
                <li data-translate="objective_3">{Objective 3}</li>
                <li data-translate="objective_4">{Objective 4}</li>
            </ul>
        </section>

        <!-- Introduction -->
        <section class="content-section">
            <p class="intro-text" data-translate="intro">{Introduction paragraph}</p>
        </section>

        <!-- Content Sections (4 sections) -->
        <section class="content-section">
            <h2 data-translate="section1_title">{Section 1 Title}</h2>
            <p data-translate="section1_text">{Section 1 Content}</p>
            <img src="images/{N:02d}_03_section1.png" alt="{Section 1 Title}" class="content-image">
        </section>

        <section class="content-section">
            <h2 data-translate="section2_title">{Section 2 Title}</h2>
            <p data-translate="section2_text">{Section 2 Content}</p>
            <img src="images/{N:02d}_04_section2.png" alt="{Section 2 Title}" class="content-image">
        </section>

        <section class="content-section">
            <h2 data-translate="section3_title">{Section 3 Title}</h2>
            <p data-translate="section3_text">{Section 3 Content}</p>
            <img src="images/{N:02d}_05_section3.png" alt="{Section 3 Title}" class="content-image">
        </section>

        <section class="content-section">
            <h2 data-translate="section4_title">{Section 4 Title}</h2>
            <p data-translate="section4_text">{Section 4 Content}</p>
            <img src="images/{N:02d}_06_section4.png" alt="{Section 4 Title}" class="content-image">
        </section>

        <!-- Interactive Quiz (5-6 questions) -->
        <section class="quiz-section">
            <h2 data-translate="quiz_title">اختبر معلوماتك</h2>
            <div class="quiz-container" id="quiz">
                <!-- Quiz questions dynamically generated by JavaScript -->
            </div>
            <div class="quiz-results" id="quizResults"></div>
        </section>

        <!-- Key Takeaways -->
        <section class="takeaways-section">
            <h2 data-translate="takeaways_title">النقاط الرئيسية</h2>
            <ul class="takeaways-list">
                <li data-translate="takeaway1">{Takeaway 1}</li>
                <li data-translate="takeaway2">{Takeaway 2}</li>
                <li data-translate="takeaway3">{Takeaway 3}</li>
                <li data-translate="takeaway4">{Takeaway 4}</li>
                <li data-translate="takeaway5">{Takeaway 5}</li>
            </ul>
        </section>

        <!-- Practical Exercise -->
        <section class="exercise-section">
            <h2 data-translate="exercise_title">تمرين عملي</h2>
            <p data-translate="exercise">{Exercise description}</p>
            <button class="complete-btn" onclick="markExerciseComplete()">
                <span data-translate="mark_complete">تم الإنجاز</span>
            </button>
        </section>

        <!-- Lesson Navigation -->
        <section class="navigation-section">
            <a href="lesson-{N-1}-interactive.html" class="nav-btn prev-btn">
                <span data-translate="previous_lesson">← الدرس السابق</span>
            </a>
            <a href="lesson-{N+1}-interactive.html" class="nav-btn next-btn">
                <span data-translate="next_lesson">الدرس التالي →</span>
            </a>
        </section>
    </main>

    <!-- Footer -->
    <footer class="site-footer">
        <div class="footer-content">
            <p>&copy; 2025 Seekapa Trading Academy. <span data-translate="all_rights">جميع الحقوق محفوظة</span>.</p>
            <p class="disclaimer" data-translate="disclaimer">
                تحذير المخاطر: التداول ينطوي على مخاطر. الأداء السابق لا يضمن النتائج المستقبلية.
            </p>
        </div>
    </footer>

    <!-- Gamification JavaScript -->
    <script>
        // XP System, Quiz Logic, Language Switching, Progress Tracking
        // (Copy exactly from lesson-01-interactive.html, lines 800-1400)
    </script>
</body>
</html>
```

---

## Translation Manifest Structure

**File**: `lesson-{N}-content-4lang.json`

**Required Structure** (72 strings × 4 languages = 288 total entries):

```json
{
  "en": {
    "title": "Lesson Title in English",
    "subtitle": "Subtitle describing lesson focus",
    "objectives": [
      "Objective 1",
      "Objective 2",
      "Objective 3",
      "Objective 4"
    ],
    "intro": "Introduction paragraph (150-250 words)",
    "section1_title": "Section 1 Title",
    "section1_text": "Section 1 content (200-300 words)",
    "section2_title": "Section 2 Title",
    "section2_text": "Section 2 content (200-300 words)",
    "section3_title": "Section 3 Title",
    "section3_text": "Section 3 content (200-300 words)",
    "section4_title": "Section 4 Title",
    "section4_text": "Section 4 content (200-300 words)",
    "takeaway1": "Key takeaway point 1",
    "takeaway2": "Key takeaway point 2",
    "takeaway3": "Key takeaway point 3",
    "takeaway4": "Key takeaway point 4",
    "takeaway5": "Key takeaway point 5",
    "exercise": "Practical exercise description",
    "quiz_q1": "Quiz question 1",
    "quiz_q1_a": "Answer option A",
    "quiz_q1_b": "Answer option B",
    "quiz_q1_c": "Answer option C",
    "quiz_q1_d": "Answer option D",
    "quiz_q1_correct": "a",  // or "b", "c", "d"
    // ... (repeat for questions 2-5)
  },
  "ar": {
    // Same 72 keys with Arabic (Khaleeji) translations
  },
  "es": {
    // Same 72 keys with Spanish (Latin American) translations
  },
  "pt": {
    // Same 72 keys with Portuguese (Brazilian) translations
  }
}
```

---

## Image Specifications

### Dimensions & Format
- **Resolution**: 1920×1080 pixels (16:9 aspect ratio for videos)
- **Or**: 1200×800 pixels (3:2 aspect ratio for simpler graphics)
- **Format**: PNG (with transparency where appropriate)
- **File Size**: 300 KB - 1.4 MB per image (compressed but high quality)
- **Color Space**: sRGB

### Naming Convention
```
{lesson_number:02d}_{image_number:02d}_{title_slug}.png

Examples:
02_01_intro_hero.png
02_02_market_types_comparison.png
02_03_forex_market_structure.png
```

### Visual Style Guidelines
- **Brand Colors**: Seekapa Forest (#1B5E3F) as primary
- **Typography**: Clean, professional sans-serif for diagrams
- **Style**: Modern, professional financial education aesthetic
- **Cultural**: Appropriate for GCC and LATAM audiences (no culturally insensitive imagery)
- **Regulatory**: No misleading financial promises or guarantees

### Image Generation Prompts

**General Template**:
```
"Professional financial education illustration for Seekapa Trading Academy showing [CONCEPT].
Modern, clean design with Seekapa brand colors (forest green #1B5E3F, champagne gold #D4AF37).
High-quality, 4K resolution, suitable for premium online course.
Photorealistic style with subtle depth and lighting.
Culturally appropriate for GCC Middle Eastern and Latin American audiences."
```

**Specific Types**:

1. **Hero/Intro Images**: Professional trader workspace, financial charts, global markets
2. **Concept Visualizations**: Diagrams, flowcharts, comparison tables
3. **Section Illustrations**: Support specific lesson content (e.g., candlestick patterns, market types)
4. **Exercise/Takeaways**: Clean summary graphics, checklist visuals

---

## JavaScript Functionality (MUST Preserve)

### 1. Language Switching
```javascript
function switchLanguage(lang) {
    document.documentElement.lang = lang;
    document.documentElement.dir = (lang === 'ar') ? 'rtl' : 'ltr';

    // Update all [data-translate] elements with content from translations
    updateTranslations(lang);

    // Save preference
    localStorage.setItem('preferred_language', lang);
}
```

### 2. XP System
```javascript
function awardXP(amount, reason) {
    const currentXP = parseInt(localStorage.getItem('total_xp') || '0');
    const newXP = currentXP + amount;
    localStorage.setItem('total_xp', newXP);

    document.getElementById('xpAmount').textContent = newXP;
    showXPNotification(amount, reason);
}

// XP Awards:
// - Complete lesson: +50 XP
// - Perfect quiz (5/5): +30 XP
// - Complete exercise: +20 XP
// - Daily streak: +10 XP per day
```

### 3. Progress Tracking
```javascript
function markLessonComplete(lessonNum) {
    const completed = JSON.parse(localStorage.getItem('completed_lessons') || '[]');
    if (!completed.includes(lessonNum)) {
        completed.push(lessonNum);
        localStorage.setItem('completed_lessons', JSON.stringify(completed));
        awardXP(50, 'Lesson Complete');
    }
}
```

### 4. Quiz System
```javascript
const quizData = [
    {
        question: translations[currentLang].quiz_q1,
        options: [
            translations[currentLang].quiz_q1_a,
            translations[currentLang].quiz_q1_b,
            translations[currentLang].quiz_q1_c,
            translations[currentLang].quiz_q1_d
        ],
        correct: translations[currentLang].quiz_q1_correct
    },
    // ... 4 more questions
];

function checkAnswers() {
    const score = calculateScore();
    if (score === 5) {
        awardXP(30, 'Perfect Quiz!');
        unlockBadge('quiz_master_' + lessonNum);
    }
}
```

---

## Responsive Design Breakpoints

```css
/* Mobile First */
@media (max-width: 640px) {
    /* Phone: Stack everything, larger touch targets */
}

@media (min-width: 641px) and (max-width: 1024px) {
    /* Tablet: 2-column layouts where appropriate */
}

@media (min-width: 1025px) {
    /* Desktop: Full multi-column layouts, sidebars */
}
```

---

## Accessibility Requirements

- ✅ Semantic HTML5 elements (`<section>`, `<article>`, `<nav>`, `<header>`, `<footer>`)
- ✅ ARIA labels where needed (`aria-label`, `role`, `aria-expanded`)
- ✅ Keyboard navigation support (Tab, Enter, Arrow keys)
- ✅ Color contrast ratio ≥ 4.5:1 (WCAG AA)
- ✅ Alt text for all images
- ✅ Focus indicators visible
- ✅ Screen reader tested

---

## Quality Checklist (Per Lesson)

**Content**:
- [ ] Title and subtitle in all 4 languages
- [ ] 4 learning objectives per language
- [ ] Introduction paragraph (150-250 words)
- [ ] 4 content sections (200-300 words each)
- [ ] 5 key takeaways
- [ ] 1 practical exercise
- [ ] 5 quiz questions with 4 options each

**Technical**:
- [ ] HTML validates (no errors)
- [ ] All CSS variables preserved
- [ ] JavaScript functions work (XP, quiz, language switching)
- [ ] Responsive on mobile (320px-2560px)
- [ ] All images load correctly
- [ ] Navigation links functional (prev/next)

**Brand**:
- [ ] Seekapa colors used correctly
- [ ] Logo displayed prominently
- [ ] Typography follows brand guidelines
- [ ] Professional tone maintained

**Translations**:
- [ ] Arabic (Khaleeji dialect) - culturally adapted
- [ ] English - professional financial education tone
- [ ] Spanish (Latin American) - Brazil/LATAM context
- [ ] Portuguese (Brazilian) - local terminology

---

## Common Pitfalls to Avoid

❌ **DO NOT:**
- Change CSS variable names or values
- Remove gamification features (XP, quizzes, badges)
- Use placeholder text ("Lorem ipsum", "TODO")
- Hardcode text (all text must be translatable via JSON)
- Break responsive design (test on mobile!)
- Use culturally insensitive imagery
- Make misleading financial promises ("Get rich quick")

✅ **DO:**
- Follow this spec exactly
- Test on multiple devices
- Validate HTML/CSS
- Check all 4 language versions
- Ensure accessibility compliance
- Use professional trading terminology

---

## File Size Targets

| File Type | Target Size | Max Size |
|-----------|-------------|----------|
| HTML | 40-60 KB | 80 KB |
| JSON manifest | 8-12 KB | 15 KB |
| Images (each) | 300 KB - 1 MB | 1.5 MB |
| Total lesson | 5-8 MB | 12 MB |

---

## Example Lesson Numbers & Topics

This spec applies to ALL lessons 02-12:

| Lesson | Topic |
|--------|-------|
| 02 | Types of Trading Markets (Forex, Stocks, Crypto, Commodities) |
| 03 | Technical Analysis Basics (Charts, Trends, Patterns) |
| 04 | Candlestick Patterns & Price Action |
| 05 | Support & Resistance Levels |
| 06 | Chart Patterns (Head & Shoulders, Triangles, Flags) |
| 07 | Trading Indicators & Oscillators (MA, RSI, MACD) |
| 08 | Risk Management & Position Sizing |
| 09 | Trading Psychology & Mindset |
| 10 | Creating a Trading Plan |
| 11 | Backtesting & Strategy Optimization |
| 12 | Live Trading & Continuous Learning |

---

## Version History

- **v1.0** (Nov 11, 2025): Initial specification based on lesson-01-interactive.html

---

**Questions?** Reference `/home/odedbe/academy/lesson-01/` for working example.
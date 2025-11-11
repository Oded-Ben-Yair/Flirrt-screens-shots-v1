# Seekapa Trading Academy - Shared Assets

This directory contains all shared assets used across all 12 lessons.

## Directory Structure

```
shared-assets/
├── css/              # Shared stylesheets (extracted from lesson-01)
├── js/               # Shared JavaScript (gamification, language switcher)
├── images/           # Common brand assets (logos, icons)
├── fonts/            # Typography files
└── README.md         # This file
```

## Brand Guidelines

**Seekapa Brand Colors:**
- Primary: Forest Green `#1B5E3F`
- Accent: Champagne Gold `#D4AF37`
- Background: `#f8f9fa`
- Text: Dark Gray `#2d3748`
- Success: `#38a169`
- Warning: `#ed8936`
- Error: `#e53e3e`

**Typography:**
- Headings: System UI fonts (San Francisco, Segoe UI, etc.)
- Body: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto

## CSS Variables

All lessons use CSS custom properties defined in `shared-assets/css/academy-core.css`:
- `--seekapa-primary: #1B5E3F;`
- `--seekapa-gold: #D4AF37;`
- `--border-radius: 12px;`
- `--spacing-unit: 8px;`

## JavaScript Modules

- `academy-core.js` - XP system, streak tracking, localStorage management
- `language-switcher.js` - 4-language support (ar, en, es, pt)
- `quiz-engine.js` - Quiz functionality with scoring
- `progress-tracker.js` - Lesson completion and navigation

## Image Specifications

All lesson images should follow these specifications:
- **Resolution**: 1200×800px (3:2 aspect ratio) or 1920×1080 (16:9)
- **Format**: PNG (with transparency where appropriate)
- **File Size**: 300 KB - 1.4 MB
- **Naming Convention**: `{lesson:02d}_{sequence:02d}_{descriptive-slug}.png`
  - Example: `02_01_global_markets.png`

## Generation Tools

Images generated using **Gemini Imagen 4.0** with Seekapa brand guidelines enforced in prompts.

## Usage in Lessons

All lessons reference shared assets using relative paths:
```html
<link rel="stylesheet" href="../shared-assets/css/academy-core.css">
<script src="../shared-assets/js/academy-core.js"></script>
```

## Maintenance

When updating shared assets, ensure backward compatibility across all 12 lessons. Test changes in at least 3 sample lessons before deploying.

# Image Generation Guide for Seekapa Trading Academy

## Tool: Gemini Imagen 4.0

All images should be generated using **Google Gemini Imagen 4.0** via the API.

## Brand Guidelines for All Images

### Required Elements
- **Primary Color**: Seekapa Forest Green (#1B5E3F) - must be prominent
- **Accent Color**: Champagne Gold (#D4AF37) - for highlights
- **Style**: Professional financial education, modern, clean, minimalist
- **Tone**: Trustworthy, sophisticated, educational

### Technical Specifications
- **Resolution**: 1200×800px (3:2 aspect ratio preferred) or 1920×1080px (16:9)
- **Format**: PNG with transparency where appropriate
- **File Size Target**: 300 KB - 1.4 MB (optimize after generation)
- **Color Space**: sRGB
- **DPI**: 72 dpi (web optimized)

### Naming Convention
```
{lesson_number:02d}_{sequence:02d}_{descriptive_slug}.png
```

Examples:
- `02_01_global_markets.png`
- `03_04_volume_analysis.png`
- `07_03_stop_loss_placement.png`

## Prompt Template Structure

Every image prompt should follow this structure:

```
[Subject/Content Description]
+ [Seekapa brand colors: forest green #1B5E3F and champagne gold #D4AF37]
+ [Style: professional financial education, modern, clean design]
+ [Technical specs: 1200x800px]
+ [Additional context or specific requirements]
```

## Example Prompts

### Good Prompt ✅
```
Professional trading education illustration showing global stock exchanges (NYSE, NASDAQ, London, Tokyo) connected with network lines, modern financial district skylines, Seekapa forest green (#1B5E3F) and champagne gold (#D4AF37) color scheme, clean minimalist design, 1200x800px
```

### Bad Prompt ❌
```
Stock market picture
```

## Content Categories

### 1. Chart/Technical Analysis Images
- Show real-looking price charts with professional indicators
- Include clear labels and annotations
- Maintain clean, uncluttered visualization
- Use Seekapa colors for trend lines, support/resistance

### 2. Concept Illustrations
- Abstract representations of trading concepts
- Use icons and symbols professionally
- Maintain visual hierarchy
- Balance text and imagery

### 3. Process Diagrams
- Clear flowcharts or step-by-step visuals
- Use arrows and connectors
- Numbered steps where appropriate
- Consistent icon style

### 4. Comparison Charts
- Side-by-side comparisons
- Use tables or parallel columns
- Highlight differences clearly
- Maintain balance and symmetry

## Quality Checklist

Before accepting an image, verify:
- [ ] Seekapa forest green (#1B5E3F) is prominent
- [ ] Champagne gold (#D4AF37) is used tastefully as accent
- [ ] Resolution is 1200×800px or 1920×1080px
- [ ] Image is professional and educational in tone
- [ ] Text (if any) is legible and well-placed
- [ ] No copyright concerns (all elements are original or properly licensed)
- [ ] File size is reasonable (< 1.5 MB)
- [ ] File name follows naming convention

## API Integration Example

```python
import google.generativeai as genai

# Configure Gemini
genai.configure(api_key="GEMINI_API_KEY")

# Generate image
model = genai.GenerativeModel('imagen-4.0-generate-preview')
prompt = "Professional trading education illustration showing candlestick charts, Seekapa forest green (#1B5E3F) and champagne gold (#D4AF37) color scheme, clean minimalist design, 1200x800px"

response = model.generate_image(
    prompt=prompt,
    number_of_images=1,
    aspect_ratio="4:3",  # For 1200x800
    safety_filter_level="block_few"
)

# Save image
with open("lesson_image.png", "wb") as f:
    f.write(response.images[0].data)
```

## Common Pitfalls to Avoid

1. **Too busy**: Keep designs clean and focused
2. **Wrong colors**: Always use Seekapa brand colors
3. **Generic stock photos**: All images should feel custom and professional
4. **Low resolution**: Never accept images below 1200×800px
5. **Inconsistent style**: Maintain visual consistency across all lesson images
6. **Text-heavy**: Limit text in images - let the HTML provide context
7. **Cultural insensitivity**: Ensure images are appropriate for GCC markets (Arabic-speaking audience)

## Accessibility Considerations

- Avoid using color alone to convey information
- Ensure sufficient contrast for readability
- Provide descriptive alt text in HTML (not in image)
- Consider color-blind friendly palettes when using multiple colors

## Final Notes

- Generate 2-3 variations of each image and select the best
- Test images at different screen sizes before finalizing
- Optimize PNG files using tools like TinyPNG or ImageOptim
- Keep source prompts documented for future reference/regeneration

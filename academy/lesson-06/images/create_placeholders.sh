#!/bin/bash

# Create 8 professional placeholder images for Lesson 6

# Image dimensions
WIDTH=1200
HEIGHT=800
DPI=96

# Seekapa brand colors
FOREST="#1B5E3F"
EMERALD="#0F5F3F"
SAGE="#7A9D8E"
GOLD="#D4AF37"
CHARCOAL="#2B2D42"
PEARL="#F8F9FA"

# 06_01_economic_indicators.png
convert -size ${WIDTH}x${HEIGHT} xc:$PEARL \
    -gravity center \
    -fill $FOREST -pointsize 72 -font "Arial-Bold" -annotate +0+0 "📊 Economic Indicators" \
    -fill $CHARCOAL -pointsize 48 -font "Arial" -annotate +0+100 "GDP • CPI • Employment • Interest Rates" \
    -fill $SAGE -pointsize 40 -font "Arial" -annotate +0+200 "Understanding Key Market Drivers" \
    -stroke $GOLD -strokewidth 3 -fill none \
    -draw "rectangle 100,100 1100,700" \
    06_01_economic_indicators.png
echo "✓ Created 06_01_economic_indicators.png"

# 06_02_central_bank_impact.png
convert -size ${WIDTH}x${HEIGHT} xc:"linear-gradient(135deg, #f0f4f0 0%, #e8f0e8 100%)" \
    -gravity center \
    -fill $FOREST -pointsize 64 -font "Arial-Bold" -annotate +0-50 "🏦 Central Bank Decisions" \
    -fill $CHARCOAL -pointsize 44 -font "Arial" -annotate +0+80 "Interest Rate Impact on Markets" \
    -fill $SAGE -pointsize 36 -font "Arial" -annotate +0+160 "Dollar Strength • Stock Markets • Bond Yields" \
    -stroke $GOLD -strokewidth 2 -fill none -draw "rectangle 150,150 1050,650" \
    06_02_central_bank_impact.png
echo "✓ Created 06_02_central_bank_impact.png"

# 06_03_earnings_reports.png
convert -size ${WIDTH}x${HEIGHT} xc:$PEARL \
    -gravity center \
    -fill $FOREST -pointsize 68 -font "Arial-Bold" -annotate +0-60 "📈 Earnings & Volatility" \
    -fill $CHARCOAL -pointsize 46 -font "Arial" -annotate +0+50 "Expected vs. Actual Results" \
    -fill $SAGE -pointsize 38 -font "Arial" -annotate +0+140 "Revenue Growth • Profit Margins • Surprises" \
    -stroke $GOLD -strokewidth 3 -fill none -draw "rectangle 120,120 1080,680" \
    06_03_earnings_reports.png
echo "✓ Created 06_03_earnings_reports.png"

# 06_04_company_metrics.png
convert -size ${WIDTH}x${HEIGHT} xc:"linear-gradient(to bottom, #fafaf0 0%, #f5f5ec 100%)" \
    -gravity center \
    -fill $FOREST -pointsize 66 -font "Arial-Bold" -annotate +0-80 "📊 Company Fundamentals" \
    -fill $CHARCOAL -pointsize 42 -font "Arial" -annotate +0+20 "Financial Health Analysis" \
    -fill $SAGE -pointsize 36 -font "Arial" -annotate +0+100 "Debt • Cash Flow • Competitive Position" \
    -fill $EMERALD -pointsize 32 -font "Arial" -annotate +0+170 "Professional Financial Analysis" \
    -stroke $GOLD -strokewidth 2 -fill none -draw "rectangle 130,130 1070,670" \
    06_04_company_metrics.png
echo "✓ Created 06_04_company_metrics.png"

# 06_05_geopolitical_events.png
convert -size ${WIDTH}x${HEIGHT} xc:$PEARL \
    -gravity center \
    -fill $FOREST -pointsize 64 -font "Arial-Bold" -annotate +0-70 "🌍 Geopolitical Risk" \
    -fill $CHARCOAL -pointsize 44 -font "Arial" -annotate +0+40 "Elections • Trade Wars • Policy Changes" \
    -fill $SAGE -pointsize 38 -font "Arial" -annotate +0+130 "Market Sentiment Impact" \
    -fill $EMERALD -pointsize 34 -font "Arial" -annotate +0+200 "Global Economic Interconnection" \
    -stroke $GOLD -strokewidth 3 -fill none -draw "rectangle 100,100 1100,700" \
    06_05_geopolitical_events.png
echo "✓ Created 06_05_geopolitical_events.png"

# 06_06_market_sentiment.png
convert -size ${WIDTH}x${HEIGHT} xc:"linear-gradient(135deg, #fef9e7 0%, #f5efe0 100%)" \
    -gravity center \
    -fill $FOREST -pointsize 66 -font "Arial-Bold" -annotate +0-60 "😨 Market Sentiment" \
    -fill $CHARCOAL -pointsize 44 -font "Arial" -annotate +0+50 "Fear & Greed Indicators" \
    -fill $SAGE -pointsize 38 -font "Arial" -annotate +0+140 "VIX • Put/Call Ratios • Investor Surveys" \
    -stroke $GOLD -strokewidth 2 -fill none -draw "rectangle 140,140 1060,660" \
    06_06_market_sentiment.png
echo "✓ Created 06_06_market_sentiment.png"

# 06_07_economic_calendar.png
convert -size ${WIDTH}x${HEIGHT} xc:$PEARL \
    -gravity center \
    -fill $FOREST -pointsize 70 -font "Arial-Bold" -annotate +0-80 "📅 Economic Calendar" \
    -fill $CHARCOAL -pointsize 46 -font "Arial" -annotate +0+20 "High-Impact Events Tracking" \
    -fill $SAGE -pointsize 38 -font "Arial" -annotate +0+110 "Event Dates • Forecasts • Impact Levels" \
    -fill $EMERALD -pointsize 34 -font "Arial" -annotate +0+190 "Professional Trading Preparation" \
    -stroke $GOLD -strokewidth 3 -fill none -draw "rectangle 110,110 1090,690" \
    06_07_economic_calendar.png
echo "✓ Created 06_07_economic_calendar.png"

# 06_08_fundamental_technical_combo.png
convert -size ${WIDTH}x${HEIGHT} xc:"linear-gradient(to right, #faf8f3 0%, #f5f0e8 50%, #faf8f3 100%)" \
    -gravity center \
    -fill $FOREST -pointsize 60 -font "Arial-Bold" -annotate -200-80 "Fundamental" \
    -fill $FOREST -pointsize 60 -font "Arial-Bold" -annotate +200-80 "Technical" \
    -fill $CHARCOAL -pointsize 42 -font "Arial" -annotate -200+40 "Economic Data" \
    -fill $CHARCOAL -pointsize 42 -font "Arial" -annotate +200+40 "Price Charts" \
    -fill $SAGE -pointsize 38 -font "Arial" -annotate +0+150 "= Comprehensive Trading Strategy" \
    -stroke $GOLD -strokewidth 3 -fill none \
    -draw "rectangle 120,120 1080,680" \
    -draw "line 600,140 600,660" \
    06_08_fundamental_technical_combo.png
echo "✓ Created 06_08_fundamental_technical_combo.png"

echo ""
echo "All 8 placeholder images created successfully!"
ls -lh *.png

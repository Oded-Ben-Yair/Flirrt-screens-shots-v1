#!/usr/bin/env python3
"""Generate placeholder images for Lesson 07 using PIL"""
import os
from PIL import Image, ImageDraw, ImageFont
import sys

# Ensure output directory exists
os.makedirs('images', exist_ok=True)

def create_placeholder(filename, title, description):
    """Create a professional placeholder image"""
    img = Image.new('RGB', (1200, 800), color='#FDFDF8')
    draw = ImageDraw.Draw(img)
    
    # Add gradient effect with overlays
    for i in range(100):
        color_value = 245 + i
        draw.rectangle([(0, i*8), (1200, (i+1)*8)], fill=(color_value, color_value, color_value))
    
    # Add border
    draw.rectangle([(0, 0), (1199, 799)], outline='#1B5E3F', width=3)
    
    # Add top banner
    draw.rectangle([(0, 0), (1200, 150)], fill='#1B5E3F')
    
    # Add text
    try:
        title_font = ImageFont.load_default()
        desc_font = ImageFont.load_default()
    except:
        title_font = ImageFont.load_default()
        desc_font = ImageFont.load_default()
    
    # Title
    draw.text((600, 50), title, fill='white', font=title_font, anchor='mm')
    
    # Description
    draw.text((600, 450), description, fill='#2B2D42', font=desc_font, anchor='mm')
    
    # Watermark
    draw.text((600, 750), 'Seekapa Trading Academy - Lesson 7', fill='#7A9D8E', font=desc_font, anchor='mm')
    
    img.save(f'images/{filename}')
    print(f'Created: {filename}')

# Create all 8 images
images = [
    ('07_01_risk_management_shield.png', 'Risk Management Shield', 'Capital Protection Concept'),
    ('07_02_position_sizing_formula.png', 'Position Sizing Formula', 'Calculation & Examples'),
    ('07_03_stop_loss_placement.png', 'Stop Loss Placement', 'Technical & Price-Based Stops'),
    ('07_04_trailing_stop.png', 'Trailing Stop', 'Profit Protection Mechanism'),
    ('07_05_risk_reward_ratio.png', 'Risk-Reward Ratio', '1:2 and 1:3 Ratio Examples'),
    ('07_06_capital_preservation.png', 'Capital Preservation', 'Equity Curve Comparison'),
    ('07_07_portfolio_risk.png', 'Portfolio Risk Dashboard', 'Multi-Position Risk Analysis'),
    ('07_08_risk_calculator.png', 'Risk Calculator', 'Position Size Calculation Tool'),
]

for filename, title, desc in images:
    create_placeholder(filename, title, desc)

print('\nAll 8 images created successfully!')

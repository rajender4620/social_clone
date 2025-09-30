#!/usr/bin/env python3
"""
Icon Generation Script for Pumpkin Social Media App
This script generates all required app icons from the base SVG design.
"""

import os
from PIL import Image, ImageDraw, ImageOps
import math

def create_pumpkin_icon(size):
    """Create a pumpkin icon of the specified size"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Scale factor for the design
    scale = size / 512
    
    # Background circle (light orange)
    bg_radius = int(240 * scale)
    center = size // 2
    draw.ellipse(
        [center - bg_radius, center - bg_radius, center + bg_radius, center + bg_radius],
        fill=(255, 243, 224, 255)  # #FFF3E0
    )
    
    # Main pumpkin body
    pumpkin_width = int(160 * scale)
    pumpkin_height = int(180 * scale)
    
    # Create pumpkin segments
    segments = 5
    segment_width = pumpkin_width // segments
    
    for i in range(segments):
        x_offset = (i - 2) * segment_width
        # Main pumpkin segment
        left = center + x_offset - segment_width//2
        top = center - pumpkin_height//2
        right = center + x_offset + segment_width//2
        bottom = center + pumpkin_height//2 - int(20 * scale)
        
        # Create gradient effect by drawing multiple ellipses
        for j in range(3):
            color_intensity = 255 - j * 20
            orange_colors = [
                (255, 140, 66),   # #FF8C42
                (255, 107, 53),   # #FF6B35  
                (229, 87, 34)     # #E55722
            ]
            color = orange_colors[min(j, 2)]
            
            offset = j * 2
            draw.ellipse(
                [left + offset, top + offset, right - offset, bottom - offset],
                fill=color + (200,)
            )
    
    # Stem
    stem_width = int(16 * scale)
    stem_height = int(25 * scale)
    stem_top = center - pumpkin_height//2 - stem_height
    
    draw.rectangle(
        [center - stem_width//2, stem_top, center + stem_width//2, center - pumpkin_height//2],
        fill=(76, 175, 80, 255)  # #4CAF50
    )
    
    # Leaf
    leaf_size = int(15 * scale)
    draw.ellipse(
        [center + leaf_size//2, stem_top, center + leaf_size*2, stem_top + leaf_size],
        fill=(46, 125, 50, 255)  # #2E7D32
    )
    
    # Highlight for 3D effect
    highlight_size = int(80 * scale)
    highlight_x = center - int(60 * scale)
    highlight_y = center - int(80 * scale)
    
    # Create radial gradient for highlight
    for i in range(highlight_size//2):
        alpha = int(100 * (1 - i/(highlight_size//2)))
        if alpha > 0:
            draw.ellipse(
                [highlight_x + i, highlight_y + i, 
                 highlight_x + highlight_size - i, highlight_y + highlight_size - i],
                fill=(255, 183, 77, alpha)  # #FFB74D with varying alpha
            )
    
    # Social connection dots
    dots = [
        (center + int(90 * scale), center - int(80 * scale), int(8 * scale), (255, 140, 66, 180)),
        (center + int(100 * scale), center - int(30 * scale), int(6 * scale), (255, 107, 53, 150)),
        (center + int(85 * scale), center + int(20 * scale), int(5 * scale), (229, 87, 34, 120))
    ]
    
    for x, y, radius, color in dots:
        draw.ellipse([x - radius, y - radius, x + radius, y + radius], fill=color)
    
    return img

def generate_all_icons():
    """Generate all required app icons"""
    
    # Icon specifications
    icons = {
        # Android icons
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
        
        # iOS icons
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
        
        # Web icons
        'web/icons/Icon-192.png': 192,
        'web/icons/Icon-512.png': 512,
        'web/icons/Icon-maskable-192.png': 192,
        'web/icons/Icon-maskable-512.png': 512,
        'web/favicon.png': 32,
    }
    
    print("Generating Pumpkin app icons...")
    
    for path, size in icons.items():
        print(f"Creating {path} ({size}x{size})")
        
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(path), exist_ok=True)
        
        # Generate icon
        icon = create_pumpkin_icon(size)
        
        # For maskable icons, add padding
        if 'maskable' in path:
            # Add 20% padding for maskable icons
            padding = int(size * 0.1)
            padded = Image.new('RGBA', (size, size), (255, 140, 66, 255))  # Orange background
            icon_resized = icon.resize((size - 2*padding, size - 2*padding), Image.Resampling.LANCZOS)
            padded.paste(icon_resized, (padding, padding), icon_resized)
            icon = padded
        
        # Save icon
        icon.save(path, 'PNG')
    
    print("✅ All icons generated successfully!")

if __name__ == "__main__":
    try:
        generate_all_icons()
    except ImportError:
        print("❌ PIL/Pillow is required. Install with: pip install Pillow")
        print("💡 Alternatively, use the individual icon files created below...")

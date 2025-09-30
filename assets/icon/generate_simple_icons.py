#!/usr/bin/env python3
"""
Simple PNG icon generator for Pumpkin app
Creates basic PNG icons using PIL (Python Imaging Library)
"""

try:
    from PIL import Image, ImageDraw
    import os
    
    def create_pumpkin_icon(size=1024, foreground_only=False):
        """Create a simple pumpkin icon"""
        # Create image with transparent background for foreground, colored for regular
        if foreground_only:
            img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        else:
            img = Image.new('RGBA', (size, size), (255, 243, 224, 255))  # Light orange background
        
        draw = ImageDraw.Draw(img)
        
        # Scale factor
        scale = size / 120
        center_x, center_y = size // 2, size // 2
        
        # Main pumpkin body (simplified as circle)
        pumpkin_size = int(70 * scale)
        pumpkin_pos = (
            center_x - pumpkin_size // 2,
            center_y - pumpkin_size // 2 + int(5 * scale),
            center_x + pumpkin_size // 2,
            center_y + pumpkin_size // 2 + int(5 * scale)
        )
        draw.ellipse(pumpkin_pos, fill=(255, 107, 53, 255))  # Orange pumpkin
        
        # Stem (simple rectangle)
        stem_width = int(8 * scale)
        stem_height = int(12 * scale)
        stem_pos = (
            center_x - stem_width // 2,
            center_y - int(35 * scale),
            center_x + stem_width // 2,
            center_y - int(35 * scale) + stem_height
        )
        draw.rectangle(stem_pos, fill=(76, 175, 80, 255))  # Green stem
        
        # Simple pumpkin ridges (vertical lines)
        line_color = (229, 87, 34, 255)  # Darker orange
        line_width = max(1, int(2 * scale))
        
        # Center line
        draw.line([
            (center_x, center_y - int(25 * scale)),
            (center_x, center_y + int(25 * scale))
        ], fill=line_color, width=line_width)
        
        # Left line
        draw.line([
            (center_x - int(15 * scale), center_y - int(20 * scale)),
            (center_x - int(15 * scale), center_y + int(20 * scale))
        ], fill=line_color, width=line_width)
        
        # Right line
        draw.line([
            (center_x + int(15 * scale), center_y - int(20 * scale)),
            (center_x + int(15 * scale), center_y + int(20 * scale))
        ], fill=line_color, width=line_width)
        
        return img
    
    def main():
        # Create directory if it doesn't exist
        os.makedirs('.', exist_ok=True)
        
        print("🎃 Generating Pumpkin PNG icons...")
        
        # Generate main icon
        print("Creating app_icon.png (1024x1024)...")
        main_icon = create_pumpkin_icon(1024, foreground_only=False)
        main_icon.save('app_icon.png', 'PNG', optimize=True)
        
        # Generate foreground icon
        print("Creating app_icon_foreground.png (1024x1024)...")
        fg_icon = create_pumpkin_icon(1024, foreground_only=True)
        fg_icon.save('app_icon_foreground.png', 'PNG', optimize=True)
        
        print("✅ Icons generated successfully!")
        print("📁 Files created in current directory:")
        print("   - app_icon.png")
        print("   - app_icon_foreground.png")
        
    if __name__ == "__main__":
        main()
        
except ImportError:
    print("❌ PIL (Pillow) not installed.")
    print("Install with: pip install Pillow")
    print("Or use the HTML generator: create_png_icons.html")
except Exception as e:
    print(f"❌ Error: {e}")
    print("Please use the HTML generator: create_png_icons.html")

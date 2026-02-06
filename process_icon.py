#!/usr/bin/env python3
"""
Process Picture1.png into a proper app icon
- Resize to 1024x1024
- Add rounded corners (watchOS style)
- Ensure proper format
"""

from PIL import Image, ImageDraw, ImageOps
import math

def add_rounded_corners(img, radius_percent=0.22):
    """Add rounded corners to an image"""
    size = img.size[0]
    radius = int(size * radius_percent)
    
    # Create a mask with rounded corners
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    # Apply the mask
    output = Image.new('RGBA', img.size, (0, 0, 0, 0))
    output.paste(img, mask=mask)
    
    return output

def process_icon(input_path, output_path, size=1024):
    """Process the input image into a proper app icon"""
    
    # Open the image
    img = Image.open(input_path)
    
    # Convert to RGBA if needed
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Get current dimensions
    width, height = img.size
    print(f"Original size: {width}x{height}")
    
    # Make it square by cropping to center
    if width != height:
        min_dim = min(width, height)
        left = (width - min_dim) // 2
        top = (height - min_dim) // 2
        right = left + min_dim
        bottom = top + min_dim
        img = img.crop((left, top, right, bottom))
        print(f"Cropped to square: {min_dim}x{min_dim}")
    
    # Resize to target size with high quality
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    print(f"Resized to: {size}x{size}")
    
    # Add rounded corners for watchOS style
    img = add_rounded_corners(img, radius_percent=0.22)
    print("Added rounded corners")
    
    # Save
    img.save(output_path, "PNG")
    print(f"Saved to: {output_path}")
    
    return img

def main():
    input_path = "Picture1.png"
    output_path = "OrangeLineTracker/OrangeLineTracker Watch App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    
    process_icon(input_path, output_path)
    
    # Also save a preview
    preview_path = "AppIcon_preview.png"
    process_icon(input_path, preview_path)

if __name__ == "__main__":
    main()

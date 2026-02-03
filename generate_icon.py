#!/usr/bin/env python3
"""
Generate Orange Line Tracker app icon
Creates a 1024x1024 PNG icon with an orange tram/metro design
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_app_icon(size=1024):
    """Create the Orange Line Tracker app icon"""
    
    # Create image with orange gradient background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background - rounded rectangle with orange gradient effect
    # Using a solid orange background for simplicity
    margin = int(size * 0.05)
    corner_radius = int(size * 0.22)  # watchOS style rounded corners
    
    # Draw rounded rectangle background
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=(255, 149, 0)  # Orange color
    )
    
    # Draw a subtle gradient overlay (darker at bottom)
    for y in range(margin, size - margin):
        alpha = int(40 * (y - margin) / (size - 2 * margin))
        draw.line(
            [(margin + corner_radius // 2, y), (size - margin - corner_radius // 2, y)],
            fill=(0, 0, 0, alpha)
        )
    
    # Draw tram/metro icon
    center_x = size // 2
    center_y = size // 2
    
    # Tram body dimensions
    tram_width = int(size * 0.5)
    tram_height = int(size * 0.35)
    tram_left = center_x - tram_width // 2
    tram_top = center_y - tram_height // 2 - int(size * 0.05)
    tram_right = center_x + tram_width // 2
    tram_bottom = tram_top + tram_height
    
    # Draw tram body (white rounded rectangle)
    body_radius = int(size * 0.08)
    draw.rounded_rectangle(
        [tram_left, tram_top, tram_right, tram_bottom],
        radius=body_radius,
        fill=(255, 255, 255),
        outline=(230, 230, 230),
        width=3
    )
    
    # Draw windows (two dark rectangles)
    window_margin = int(size * 0.04)
    window_height = int(tram_height * 0.4)
    window_width = int((tram_width - 3 * window_margin) / 2)
    window_top = tram_top + int(tram_height * 0.15)
    
    # Left window
    draw.rounded_rectangle(
        [tram_left + window_margin, window_top,
         tram_left + window_margin + window_width, window_top + window_height],
        radius=int(size * 0.02),
        fill=(50, 50, 60)
    )
    
    # Right window
    draw.rounded_rectangle(
        [tram_right - window_margin - window_width, window_top,
         tram_right - window_margin, window_top + window_height],
        radius=int(size * 0.02),
        fill=(50, 50, 60)
    )
    
    # Draw orange stripe on tram body
    stripe_top = window_top + window_height + int(size * 0.02)
    stripe_height = int(size * 0.04)
    draw.rectangle(
        [tram_left + window_margin, stripe_top,
         tram_right - window_margin, stripe_top + stripe_height],
        fill=(255, 149, 0)
    )
    
    # Draw wheels
    wheel_radius = int(size * 0.04)
    wheel_y = tram_bottom + wheel_radius // 2
    wheel_color = (80, 80, 80)
    
    # Left wheel
    draw.ellipse(
        [tram_left + int(tram_width * 0.2) - wheel_radius,
         wheel_y - wheel_radius,
         tram_left + int(tram_width * 0.2) + wheel_radius,
         wheel_y + wheel_radius],
        fill=wheel_color
    )
    
    # Right wheel
    draw.ellipse(
        [tram_right - int(tram_width * 0.2) - wheel_radius,
         wheel_y - wheel_radius,
         tram_right - int(tram_width * 0.2) + wheel_radius,
         wheel_y + wheel_radius],
        fill=wheel_color
    )
    
    # Draw track line
    track_y = wheel_y + wheel_radius + int(size * 0.02)
    track_thickness = int(size * 0.015)
    draw.rectangle(
        [margin + corner_radius, track_y,
         size - margin - corner_radius, track_y + track_thickness],
        fill=(255, 255, 255, 200)
    )
    
    # Draw station dots on track
    dot_radius = int(size * 0.015)
    dot_y = track_y + track_thickness // 2
    for i in range(5):
        dot_x = margin + corner_radius + int((size - 2 * margin - 2 * corner_radius) * i / 4)
        draw.ellipse(
            [dot_x - dot_radius, dot_y - dot_radius,
             dot_x + dot_radius, dot_y + dot_radius],
            fill=(255, 255, 255)
        )
    
    return img

def main():
    # Generate the icon
    icon = create_app_icon(1024)
    
    # Save to the Watch App assets
    output_path = "OrangeLineTracker/OrangeLineTracker Watch App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    icon.save(output_path, "PNG")
    print(f"Icon saved to: {output_path}")

if __name__ == "__main__":
    main()

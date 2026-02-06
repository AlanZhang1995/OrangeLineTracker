#!/usr/bin/env python3
"""
Generate VTA Transit Tracker app icon
Minimalist design with three colored lines + VTA text + commuter figure
"""

from PIL import Image, ImageDraw, ImageFont
import math

def create_app_icon(size=1024):
    """Create the VTA Transit Tracker app icon - minimalist style"""
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background - dark navy/charcoal for modern look
    margin = int(size * 0.0)
    corner_radius = int(size * 0.22)
    bg_color = (30, 35, 45)  # Dark charcoal
    
    draw.rounded_rectangle(
        [margin, margin, size - margin, size - margin],
        radius=corner_radius,
        fill=bg_color
    )
    
    # Line colors (VTA official-ish colors)
    orange = (255, 149, 0)
    blue = (0, 122, 255)
    green = (52, 199, 89)
    
    # Draw three horizontal lines representing transit lines
    line_thickness = int(size * 0.035)
    line_start_x = int(size * 0.12)
    line_end_x = int(size * 0.88)
    
    # Lines positioned in upper portion
    line_y_start = int(size * 0.28)
    line_spacing = int(size * 0.09)
    
    # Orange line (top)
    draw.rounded_rectangle(
        [line_start_x, line_y_start, line_end_x, line_y_start + line_thickness],
        radius=line_thickness // 2,
        fill=orange
    )
    
    # Blue line (middle)
    blue_y = line_y_start + line_spacing
    draw.rounded_rectangle(
        [line_start_x, blue_y, line_end_x, blue_y + line_thickness],
        radius=line_thickness // 2,
        fill=blue
    )
    
    # Green line (bottom)
    green_y = blue_y + line_spacing
    draw.rounded_rectangle(
        [line_start_x, green_y, line_end_x, green_y + line_thickness],
        radius=line_thickness // 2,
        fill=green
    )
    
    # Draw station dots on each line
    dot_radius = int(size * 0.018)
    num_dots = 5
    for i in range(num_dots):
        dot_x = line_start_x + int((line_end_x - line_start_x) * i / (num_dots - 1))
        # Orange line dots
        draw.ellipse(
            [dot_x - dot_radius, line_y_start + line_thickness//2 - dot_radius,
             dot_x + dot_radius, line_y_start + line_thickness//2 + dot_radius],
            fill=(255, 255, 255)
        )
        # Blue line dots
        draw.ellipse(
            [dot_x - dot_radius, blue_y + line_thickness//2 - dot_radius,
             dot_x + dot_radius, blue_y + line_thickness//2 + dot_radius],
            fill=(255, 255, 255)
        )
        # Green line dots
        draw.ellipse(
            [dot_x - dot_radius, green_y + line_thickness//2 - dot_radius,
             dot_x + dot_radius, green_y + line_thickness//2 + dot_radius],
            fill=(255, 255, 255)
        )
    
    # Draw commuter figure (simple stick figure with briefcase)
    figure_center_x = int(size * 0.35)
    figure_bottom = int(size * 0.82)
    figure_scale = size * 0.0018
    white = (255, 255, 255)
    
    # Head
    head_radius = int(28 * figure_scale)
    head_y = figure_bottom - int(180 * figure_scale)
    draw.ellipse(
        [figure_center_x - head_radius, head_y - head_radius,
         figure_center_x + head_radius, head_y + head_radius],
        fill=white
    )
    
    # Body
    body_top = head_y + head_radius + int(5 * figure_scale)
    body_bottom = figure_bottom - int(70 * figure_scale)
    body_width = int(8 * figure_scale)
    draw.rounded_rectangle(
        [figure_center_x - body_width, body_top,
         figure_center_x + body_width, body_bottom],
        radius=body_width // 2,
        fill=white
    )
    
    # Legs (walking pose)
    leg_width = int(7 * figure_scale)
    # Left leg (forward)
    left_leg_x = figure_center_x - int(15 * figure_scale)
    draw.rounded_rectangle(
        [left_leg_x - leg_width, body_bottom - int(10 * figure_scale),
         left_leg_x + leg_width, figure_bottom],
        radius=leg_width // 2,
        fill=white
    )
    # Right leg (back)
    right_leg_x = figure_center_x + int(15 * figure_scale)
    draw.rounded_rectangle(
        [right_leg_x - leg_width, body_bottom - int(10 * figure_scale),
         right_leg_x + leg_width, figure_bottom - int(15 * figure_scale)],
        radius=leg_width // 2,
        fill=white
    )
    
    # Arms
    arm_width = int(6 * figure_scale)
    arm_y = body_top + int(20 * figure_scale)
    # Left arm (holding briefcase)
    draw.rounded_rectangle(
        [figure_center_x - int(35 * figure_scale), arm_y,
         figure_center_x - int(20 * figure_scale), arm_y + int(50 * figure_scale)],
        radius=arm_width // 2,
        fill=white
    )
    # Right arm (swinging)
    draw.rounded_rectangle(
        [figure_center_x + int(15 * figure_scale), arm_y,
         figure_center_x + int(30 * figure_scale), arm_y + int(40 * figure_scale)],
        radius=arm_width // 2,
        fill=white
    )
    
    # Briefcase
    briefcase_x = figure_center_x - int(50 * figure_scale)
    briefcase_y = arm_y + int(50 * figure_scale)
    briefcase_w = int(35 * figure_scale)
    briefcase_h = int(28 * figure_scale)
    draw.rounded_rectangle(
        [briefcase_x, briefcase_y,
         briefcase_x + briefcase_w, briefcase_y + briefcase_h],
        radius=int(5 * figure_scale),
        fill=orange,
        outline=white,
        width=int(3 * figure_scale)
    )
    # Briefcase handle
    handle_width = int(12 * figure_scale)
    draw.rounded_rectangle(
        [briefcase_x + briefcase_w//2 - handle_width//2, briefcase_y - int(8 * figure_scale),
         briefcase_x + briefcase_w//2 + handle_width//2, briefcase_y + int(2 * figure_scale)],
        radius=int(3 * figure_scale),
        fill=None,
        outline=white,
        width=int(3 * figure_scale)
    )
    
    # VTA text
    vta_x = int(size * 0.55)
    vta_y = int(size * 0.58)
    
    # Try to use a bold font, fallback to default
    try:
        font_size = int(size * 0.18)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", font_size)
    except:
        font = ImageFont.load_default()
    
    # Draw VTA text with slight shadow for depth
    shadow_offset = int(size * 0.005)
    draw.text((vta_x + shadow_offset, vta_y + shadow_offset), "VTA", 
              font=font, fill=(0, 0, 0, 100))
    draw.text((vta_x, vta_y), "VTA", font=font, fill=white)
    
    return img

def main():
    # Generate the icon
    icon = create_app_icon(1024)
    
    # Save to the Watch App assets
    output_path = "OrangeLineTracker/OrangeLineTracker Watch App/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    icon.save(output_path, "PNG")
    print(f"Icon saved to: {output_path}")
    
    # Also save a preview
    preview_path = "AppIcon_preview.png"
    icon.save(preview_path, "PNG")
    print(f"Preview saved to: {preview_path}")

if __name__ == "__main__":
    main()

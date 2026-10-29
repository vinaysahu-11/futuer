import math
from PIL import Image, ImageDraw, ImageFilter

def create_futuer_logo(size=1024):
    # Master image with RGBA
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 1. Background Rounded Squircle with Subtle Gradient
    margin = int(size * 0.04)
    radius = int(size * 0.22)
    bg_box = [margin, margin, size - margin, size - margin]

    # Create gradient background
    bg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    bg_draw = ImageDraw.Draw(bg)
    
    # Draw radial/diagonal dark tech gradient
    for y in range(size):
        ratio = y / size
        # Midnight Navy #0B1120 to Deep Obsidian #030712
        r = int(11 * (1 - ratio) + 3 * ratio)
        g = int(17 * (1 - ratio) + 7 * ratio)
        b = int(32 * (1 - ratio) + 18 * ratio)
        bg_draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # Mask with rounded rectangle
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle(bg_box, radius=radius, fill=255)
    
    # Apply mask to background
    base_icon = Image.composite(bg, img, mask)
    draw = ImageDraw.Draw(base_icon)

    # 2. Glowing Outer Ring / Border
    border_color = (0, 229, 255, 60) # Neon Cyan 25% opacity
    draw.rounded_rectangle(bg_box, radius=radius, outline=border_color, width=int(size * 0.015))

    # 3. Inner glowing tech elements
    center_x, center_y = size // 2, size // 2

    # Draw ambient glow in center
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_radius = int(size * 0.35)
    glow_draw.ellipse(
        [center_x - glow_radius, center_y - glow_radius, center_x + glow_radius, center_y + glow_radius],
        fill=(0, 229, 255, 50)
    )
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(size * 0.08)))
    base_icon = Image.alpha_composite(base_icon, glow)
    draw = ImageDraw.Draw(base_icon)

    # 4. Stylized Futuristic "F" & Connected Device Ring Glyph
    # Primary colors: Electric Cyan (0, 229, 255) & Cyber Purple/Indigo (99, 102, 241)
    
    # Outer Tech Arc (Shield / Orbit of connectivity)
    arc_box = [center_x - int(size * 0.32), center_y - int(size * 0.32), 
               center_x + int(size * 0.32), center_y + int(size * 0.32)]
    draw.arc(arc_box, start=40, end=270, fill=(0, 229, 255, 230), width=int(size * 0.035))
    draw.arc(arc_box, start=290, end=20, fill=(99, 102, 241, 230), width=int(size * 0.035))

    # Satellite Device Nodes (Dots on the orbit)
    node1_angle = math.radians(40)
    node1_x = center_x + int(size * 0.32 * math.cos(node1_angle))
    node1_y = center_y + int(size * 0.32 * math.sin(node1_angle))
    draw.ellipse([node1_x - 22, node1_y - 22, node1_x + 22, node1_y + 22], fill=(0, 229, 255, 255))

    node2_angle = math.radians(270)
    node2_x = center_x + int(size * 0.32 * math.cos(node2_angle))
    node2_y = center_y + int(size * 0.32 * math.sin(node2_angle))
    draw.ellipse([node2_x - 22, node2_y - 22, node2_x + 22, node2_y + 22], fill=(99, 102, 241, 255))

    # Center Stylized "F" with sharp futuristic geometric cuts
    # Vertical spine of "F"
    f_left = center_x - int(size * 0.16)
    f_top = center_y - int(size * 0.22)
    f_bottom = center_y + int(size * 0.22)
    spine_w = int(size * 0.075)

    # Draw Vertical Spine
    draw.rounded_rectangle([f_left, f_top, f_left + spine_w, f_bottom], radius=16, fill=(255, 255, 255, 255))

    # Top horizontal bar of "F"
    top_bar_w = int(size * 0.32)
    draw.rounded_rectangle([f_left, f_top, f_left + top_bar_w, f_top + spine_w], radius=16, fill=(0, 229, 255, 255))
    # Top bar cyan accent point
    draw.ellipse([f_left + top_bar_w - 20, f_top, f_left + top_bar_w + 14, f_top + spine_w], fill=(255, 255, 255, 255))

    # Middle horizontal bar of "F" (shorter with gradient accent)
    mid_y = f_top + int((f_bottom - f_top) * 0.42)
    mid_bar_w = int(size * 0.22)
    draw.rounded_rectangle([f_left, mid_y, f_left + mid_bar_w, mid_y + spine_w], radius=14, fill=(99, 102, 241, 255))

    # Pulse Connection Node at bottom of F
    draw.ellipse([f_left + spine_w//2 - 16, f_bottom - 16, f_left + spine_w//2 + 16, f_bottom + 16], fill=(0, 229, 255, 255))

    return base_icon

if __name__ == '__main__':
    master = create_futuer_logo(1024)
    master.save('d:/project/futuer/web/icons/Icon-512.png')
    
    # Resizing
    sizes = {
        'd:/project/futuer/web/icons/Icon-192.png': (192, 192),
        'd:/project/futuer/web/icons/Icon-512.png': (512, 512),
        'd:/project/futuer/web/icons/Icon-maskable-192.png': (192, 192),
        'd:/project/futuer/web/icons/Icon-maskable-512.png': (512, 512),
        'd:/project/futuer/web/favicon.png': (64, 64),
        'd:/project/futuer/android/app/src/main/res/mipmap-mdpi/ic_launcher.png': (48, 48),
        'd:/project/futuer/android/app/src/main/res/mipmap-hdpi/ic_launcher.png': (72, 72),
        'd:/project/futuer/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': (96, 96),
        'd:/project/futuer/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': (144, 144),
        'd:/project/futuer/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': (192, 192),
    }

    # Ensure assets directory exists for in-app logo
    import os
    os.makedirs('d:/project/futuer/assets/images', exist_ok=True)
    master.save('d:/project/futuer/assets/images/futuer_logo.png')

    for path, (w, h) in sizes.items():
        resized = master.resize((w, h), Image.Resampling.LANCZOS)
        resized.save(path)
    print("Successfully generated all Futuer logos and app icons!")
